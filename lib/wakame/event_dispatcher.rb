
module Wakame
  class EventDispatcher
    class << self
      
      def instance
        if @instance.nil?
          @instance = self.new
        end
        @instance
      end
      
      def subscribe(event_class, *args, &blk)
        self.instance.subscribe(event_class, *args, &blk)
      end

      def unsubscribe(ticket)
        self.instance.unsubscribe(ticket)
      end

      def subscribe_once(event_class, *args, &blk)
        tkt = self.subscribe(event_class, *args) { |event|
          begin
            blk.call(event) if blk
          ensure
            self.unsubscribe(tkt)
          end
        }
      end

      def fire_event(event_obj)
        self.instance.fire_event(event_obj)
      end

      def reset
        @instance = nil
      end

    end
    
    include ThreadImmutable

    def initialize
      @event_handlers = {}
      @tickets = {}

      @unsubscribe_queue = []
    end

    def subscribe(event_class, *args, &blk)
      event_class = case event_class
                    when Class
                      event_class
                    when String
                      Util.str2const(event_class)
                    else
                      raise ArgumentError, "event_class has to be a form of String or Class type"
                    end

      StatusDB.barrier {
        tlist = @event_handlers[event_class]
        if tlist.nil?
          tlist = @event_handlers[event_class] = []
        end
        
        tickets = []
        args.each { |o|
          tickets << Util.gen_id
          @tickets.store(tickets.last, [event_class, o])
          tlist << tickets.last
        }
        
        if blk
          tickets << Util.gen_id
          @tickets.store(tickets.last, [event_class, blk])
          tlist << tickets.last
        end
        
        # Return in array if num of ticket to be returned is more than or equal 2.
        tickets.size > 1 ? tickets : tickets.first
      }
    end

    def unsubscribe(ticket)
      unless @tickets.has_key?(ticket)
        #Wakame.log.warn("EventHander.unsubscribe(#{ticket}) has been tried but the ticket was not registered.")
        return nil
      end
      
      StatusDB.barrier {
        Wakame.log.debug("#{self.class}.unsubscribe(#{ticket})")

        @unsubscribe_queue << ticket
        ticket
      }
    end
    
    FIRE_EVENT_LOG_IGNORE_EVENTS = [Wakame::Event::AgentPong]

    def fire_event(event_obj)
      raise ArgumentError unless event_obj.is_a?(Event::Base)

      if Wakame.log.level == 0 && !FIRE_EVENT_LOG_IGNORE_EVENTS.member?(event_obj.class)
        Wakame.log.debug("Event #{event_obj.class} has been fired:" + (event_obj.log_message.nil? ? '' : (' ' + event_obj.log_message)) )
      end
      tlist = @event_handlers[event_obj.class]
      return if tlist.nil?

      run_callbacks = proc {
        @unsubscribe_queue.each { |t|
          @tickets.delete(t)
          tlist.delete(t)
        }

        tlist.each { |t|
          ary = @tickets[t]
          c = ary[1]
          if c.nil?
            next
          end
          
          begin 
            c.call(event_obj)
          rescue => e
            Wakame.log.error(e)
            #raise e
          end
        }
        
        @unsubscribe_queue.each { |t|
          @tickets.delete(t)
          tlist.delete(t)
        }
      }
    
      #@handler_run_queue.push(run_handlers)
      
      StatusDB.barrier {
        begin 
          run_callbacks.call
        rescue => e
          Wakame.log.error(e)
        end
      }
    end
    
    def reset(event_class=nil)
      if event_class.nil?
        @event_handlers.clear
        @tickets.clear
      else
        unless @event_handlers[event_class.to_s].nil?
          @event_handlers[event_class.to_s].each_key { |k|
            @tickets.delete(k)
          }
          @event_handlers[event_class.to_s].clear
        end
      end
    end
    thread_immutable_methods :reset

  end

  ED = EventDispatcher
end
