
require 'wakame/util'

module Wakame
  class Scheduler
    def initialize
      @channels = {}
    end

    def add_sequence(key, seq)
      @channels[key]=seq
    end


    def next_event(time)
      n = @channels.collect { |k, seq|
        seq.next_event(time)
      }
      n.compact!
      n = n.sort {|a,b| a[0] <=> b[0] }
      n.first
    end


    class Sequence
      def next_event(time)
      end

      def value_at(time)
      end
    end


    class LoopSequence < Sequence
      def initialize(timed_seq)
        raise ArgumentError unless timed_seq.is_a?(TimedSequence)
        @timed_sequence = timed_seq
      end


      def next_event(time)
        @timed_sequence.start_at ||= time
        unless @timed_sequence.range_check?(time)
          @timed_sequence.start_at = time
        end

        event = @timed_sequence.next_event(time)
        if event.nil?
          puts "overwrap : #{time}"
          # Here comes means that the current offset time is larger than the last offset time.
          # So the value at next first offset time will become the return value.
          f = @timed_sequence.first_event
          #l = @timed_sequence.last_event
          
          offset = ((@timed_sequence.start_at + @timed_sequence.duration) - time) + f[0]
          
          event = [offset, f[1]]
        end
        event
      end

      def value_at(time)
        @timed_sequence.start_at ||= time
        unless @timed_sequence.range_check?(time)
          @timed_sequence.start_at = time
        end
        #next_event(time)
        @timed_sequence.value_at(time)
      end

    end


    class TimedSequence
      attr_accessor :start_at

      def initialize(*args)
        @event_list = SortedHash.new

        if args.size == 1
          case args[0]
          when SortedHash
            @event_list = args[0]
          when Array
            args[0].each { |a|
              @event_list[a[0]] = a[1]
            }
          end
        elsif args.size > 1 && args.all? { |a| a.is_a?(Array) && a.size == 2 }
          ary.each { |a|
            @event_list[a[0]] = a[1]
          }
        end

        @event_list[0]=1 if @event_list.empty?
      end

      def set(offset_time, value)
        if value.nil?
          @event_list.delete(offset_time)
        else
          @event_list[offset_time] = value
        end
      end

      def []=(offset_time, value)
        set(offset_time, value)
      end

      def next_event(time)
        if @start_at > time
          event = first_event
        elsif @start_at + duration <= time
          event = nil
        else
          event = @event_list.find { |k, v|
            start_at + k > time
          }
        end

        return nil if event.nil?

        # Set the offset time (in sec) from the given absolute time
        event[0] = (@start_at + event[0].to_f) - time
        event
      end

      def first_event
        [@event_list.first_key, @event_list.first]
      end

      def last_event
        [@event_list.last_key, @event_list.last]
      end

      def value_at(time)
        return nil unless range_check?(time)
        return @event_list.last if (start_at + @event_list.last_key) <= time 

        pos=0
        @event_list.find { |k, v|
          #puts "#{start_at} + #{k} > #{time}"
          next true if start_at + k >= time
          pos += 1
          false
        }
        #puts "pos=#{pos}"
        @event_list[@event_list.keys[((pos-1) < 0 ? 0 : (pos-1))]]
      end

      def duration
        @event_list.last_key
      end

      def range_check?(time)
        raise "start_at is not set (=nil)" if start_at.nil?
        res = Range.new(start_at, start_at + duration.to_f).include?(time)
        #Wakame.log.debug("#{self.class}.range_check?(#{start_at}, #{start_at + duration.to_f}).include?(#{time})=#{res}")
        res
      end

    end


    class UnitTimeSequence < TimedSequence
      # Snap to the begging of the period
      def start_at=(time)
        @start_at = Time.at(time.tv_sec - (time.tv_sec % duration))
      end

      require 'time'

      def set(offset_time, value)
        offset_time = case offset_time
                      when String
                        t=Time.parse(offset_time)
                        t.tv_sec % duration
                      else
                        offset_time
                      end
        super(offset_time, value) if offset_time < duration
        self
      end

      def duration
        raise NotImplementedError
      end
    end

    class PerMinuteSequence < UnitTimeSequence
      MINUTE_IN_SEC=60

      def duration
        MINUTE_IN_SEC
      end
    end


    class PerHourSequence < UnitTimeSequence
      HOUR_IN_SEC=60 * 60

      def duration
        HOUR_IN_SEC
      end
    end

    class PerDaySequence < UnitTimeSequence
      DAY_IN_SEC=60 * 60 * 24

      def duration
        DAY_IN_SEC
      end
    end

    class PerWeekSequence < UnitTimeSequence
      WEEK_IN_SEC=60 * 60 * 24 * 7
      def duration
        WEEK_IN_SEC
      end
    end

    require 'observer'

    class SequenceTimer < EM::PeriodicTimer
      include Observable

      def initialize(seq)
        @sequence = seq
        super(0) {
          tnow = Time.now
          v = @sequence.value_at(tnow)
          self.changed
          self.notify_observers(v)

          ev = @sequence.next_event(tnow)
          if ev.nil?
            # Terminate this time when it runs out the event to be processed
            Wakame.log.debug("#{self.class}: Quit the timer.")
            cancel
          else
            @interval = ev[0]
            Wakame.log.debug("#{tnow + ev[0]} - #{tnow}(offset sec=#{ev[0]}) : #{ev[1]}")
          end
        }
      end

      
    end
    
  end
end
