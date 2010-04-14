
require 'thread'
require 'timeout'


module Wakame
  class CancelActionError < StandardError; end
  class CancelBroadcast < StandardError; end
  class GlobalLockError < StandardError; end

  module MasterManagers
    class ActionManager
      include MasterManager
      attr_reader :active_jobs, :lock_queue

      def master
        Wakame::Master.instance
      end

      def command_queue
        master.command_queue
      end

      def agent_monitor
        master.agent_monitor
      end

      def initialize()
        @active_jobs = {}
        @job_history = []
        @lock_queue = LockQueue.new
      end

      def init
      end

      def terminate
      end

      def cancel_action(job_id)
        job_context = @active_jobs[job_id]
        if job_context.nil?
          Wakame.log.warn("JOB ID #{job_id} was not running.")
          return
        end
        
        return if job_context[:complete_at]

        root_act = job_context[:root_action]

        walk_subactions = proc { |a|
          if a.status == :running && (a.target_thread && a.target_thread.alive?) && a.target_thread != Thread.current
            Wakame.log.debug "Raising CancelBroadcast exception: #{a.class} #{a.target_thread}(#{a.target_thread.status}), current=#{Thread.current}"
            # Broadcast the special exception to all
            a.target_thread.raise(CancelBroadcast, "It's broadcasted from #{a.class}")
            # IMPORTANT: Ensure the worker thread to handle the exception.
            #Thread.pass
          end
          a.subactions.each { |n|
            walk_subactions.call(n)
          }
        }

        begin
          Thread.critical = true
          walk_subactions.call(root_act)
        ensure
          Thread.critical = false
          # IMPORTANT: Ensure the worker thread to handle the exception.
          Thread.pass
        end
      end

      def trigger_action(action=nil, &blk)
        if blk 
          action = Action::ProcAction.new(blk)
        end

        raise ArgumentError unless action.is_a?(Action)
        context = create_job_context(action)
        action.action_manager = self
        action.job_id = context[:job_id]

        run_action(action)
        action.job_id
      end


      def run_action(action)
        raise ArgumentError unless action.is_a?(Action)
        job_context = @active_jobs[action.job_id]
        raise "The job session is killed.: job_id=#{action.job_id}" if job_context.nil?

        EM.next_tick {

          begin
            
            if job_context[:start_at].nil?
              job_context[:start_at] = Time.new
              ED.fire_event(Event::JobStart.new(action.job_id))
            end

            EM.defer proc {
              res = nil
              begin
                action.bind_thread(Thread.current)
                action.status = :running
                Wakame.log.debug("Start action : #{action.class.to_s} #{action.parent_action.nil? ? '' : ('sub-action of ' + action.parent_action.class.to_s)}")
                ED.fire_event(Event::ActionStart.new(action))
                begin
                  action.run
                  action.completion_status = :succeeded
                  Wakame.log.debug("Complete action : #{action.class.to_s}")
                  ED.fire_event(Event::ActionComplete.new(action))
                end
              rescue CancelBroadcast => e
                Wakame.log.info("Received cancel signal: #{e}")
                action.completion_status = :canceled
                begin
                  action.on_canceled
                rescue => e
                  Wakame.log.error(e)
                end
                ED.fire_event(Event::ActionFailed.new(action, e))
                res = e
              rescue => e
                Wakame.log.error("Failed action : #{action.class.to_s} due to #{e}")
                Wakame.log.error(e)
                action.completion_status = :failed
                begin
                  action.on_failed
                rescue => e
                  Wakame.log.error(e)
                end
                ED.fire_event(Event::ActionFailed.new(action, e))
                # Escalate the cancelation event to parents.
                unless action.parent_action.nil?
                  action.parent_action.notify(e)
                end
                # Force to cancel the current job when the root action ignored the elevated exception.
                if action === job_context[:root_action]
                  Wakame.log.warn("The escalated exception (#{e.class}) has reached to the root action (#{action.class}). Forcing to cancel the current job #{job_context[:job_id]}")
                  cancel_action(job_context[:job_id]) #rescue Wakame.log.error($!)
                end
                res = e
              ensure
                action.status = :complete
                action.bind_thread(nil)
              end

              StatusDB.pass {
                process_job_complete(action, res)
              }
            }
          rescue => e
            Wakame.log.error(e)
          end
        }
      end

      private
      def create_job_context(root_action)
        raise ArgumentError unless root_action.is_a?(Action)
        root_action.job_id = job_id = Wakame.gen_id

        @active_jobs[job_id] = {
          :job_id=>job_id,
          :create_at=>Time.now,
          :start_at=>nil,
          :complete_at=>nil,
          :completion_status=>nil,
          :root_action=>root_action,
          :notes=>{}
        }
      end

      def process_job_complete(action, res)
        job_id = action.job_id
        job_context = @active_jobs[job_id] || return

        actary = []
        job_context[:root_action].walk_subactions {|a| actary << a }
        #Wakame.log.debug(actary.collect{|a| {a.class.to_s=>a.status}}.inspect)
        
        actary.all? { |act| act.status == :complete } || return
        @lock_queue.quit(job_id)

        if res.is_a?(Exception)
          job_context[:exception]=res
        end

        job_context[:complete_at]=Time.now
        
        if actary.all? { |act| act.completion_status == :succeeded }
          end_status = :succeeded
        else
          end_status = :failed
        end
        job_context[:completion_status] = end_status
        
        case end_status
        when :succeeded
          ED.fire_event(Event::JobSuccess.new(action.job_id))
        when :failed
          ED.fire_event(Event::JobFailed.new(action.job_id, res))
        end
        ED.fire_event(Event::JobComplete.new(action.job_id, end_status))
        
        @active_jobs.delete(job_id)
      end

    end

    class LockQueue
      def initialize()
        @locks = {}
        @id2res = {}

        @self_m = ::Mutex.new

        @queue_by_thread = {}
        @qbt_m = ::Mutex.new
      end
      
      def set(resource, id)
        @self_m.synchronize {
          # Ths Job ID already holds/reserves the lock regarding the resource.
          return if @id2res.has_key?(id) && @id2res[id].has_key?(resource.to_s)
        
          @locks[resource.to_s] ||= []
          @id2res[id] ||= {}
          
          @id2res[id][resource.to_s]=1
          @locks[resource.to_s] << id
        }
        Wakame.log.debug("#{self.class}: set(#{resource.to_s}, #{id})" + "\n#{self.inspect}")
      end

      def reset()
        @self_m.synchronize {
          @locks.keys { |k|
            @locks[k].clear
          }
          @id2res.clear
        }
      end

      def test(id)
        @self_m.synchronize {
          reslist = @id2res[id]
          return :pass if reslist.nil? || reslist.empty?
          
          if reslist.keys.all? { |r| id == @locks[r.to_s][0] }
            return :runnable
          else
            return :wait
          end
        }
      end

      def wait(id, tout=60*30)
        @qbt_m.synchronize { @queue_by_thread[Thread.current] = ::Queue.new }

        timeout(tout) {
          while test(id) == :wait
            Wakame.log.debug("#{self.class}: Job #{id} waits for locked resouces: #{@id2res[id].keys.join(', ')}")
            break if id == @queue_by_thread[Thread.current].deq
          end
        }
      ensure
        @qbt_m.synchronize { @queue_by_thread.delete(Thread.current) }
      end
      
      def quit(id)
        case test(id)
        when :runnable, :wait
          @self_m.synchronize {
            @id2res[id].keys.each { |r| @locks[r.to_s].delete_if{ |i| i == id } }
            @locks.delete_if{ |k,v| v.nil? || v.empty? }
          }
          @qbt_m.synchronize {
            @queue_by_thread.each {|t, q| q.enq(id) }
          }
        end
        
        @id2res.delete(id)
        Wakame.log.debug("#{self.class}: quit(#{id})" + "\n#{self.inspect}")
      end

      def clear_resource(resource)
      end

      def inspect
        output = @locks.collect { |k, lst|
          [k, lst].flatten
        }
        return "" if output.empty?

        # Table display
        maxcolws = (0..(output.size)).zip(*output).collect { |i| i.shift; i.map!{|i| (i.nil? ? "" : i).length }.max }
        maxcol = maxcolws.size
        maxcolws.reverse.each { |i| 
          break if i > 0
          maxcol -= 1
        }

        textrows = output.collect { |x|
          buf=""
          maxcol.times { |n|
            buf << "|" + (x[n] || "").ljust(maxcolws[n])
          }
          buf << "|"
        }

        "+" + (["-"] * (textrows[0].length - 2)).join('') + "+\n" + \
        textrows.join("\n") + \
        "\n+" + (["-"] * (textrows[0].length - 2)).join('')+ "+"
      end
    end
  end
end
