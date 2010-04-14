
require 'thread'

module EventMachine
#   def self::defer op, callback = nil
#     @need_threadqueue ||= 0
#     if @need_threadqueue == 0
#       @need_threadqueue = 1
#       require 'thread'
#       @threadqueue = Queue.new
#       @resultqueue = Queue.new
#       @thread_g = ThreadGroup.new
#       20.times {|ix|
#         t = Thread.new {
#           my_ix = ix
#           loop {
#             op,cback = @threadqueue.pop
#             begin
#               result = op.call
#               @resultqueue << [result, cback]
#             rescue => e
#               puts "#{e} in EM defer thread pool : #{Thread.current}"
#               raise e
#             ensure
#               EventMachine.signal_loopbreak
#             end
#           }
#         }
#         @thread_g.add(t)
#       }
#     end
#
#     @threadqueue << [op,callback]
#   end

  # Redefine EM's threadpool
  def self.spawn_threadpool
    until @threadpool.size == 20
      thread = Thread.new {
        loop {
          op, cback = *@threadqueue.pop
          begin
            result = op.call
            @resultqueue << [result, cback]
          rescue => e
            puts "#{e} in EM defer thread pool : #{Thread.current}"
          ensure
            EventMachine.signal_loopbreak
          end
        }
      }
      @threadpool << thread
    end
  end
  
  def self.barrier(&blk)
    # Presumably, Thread.main will return the EM main loop thread.
    if EM.reactor_thread?
      return blk.call
    end

    raise "Eventmachine is not ready to accept the next_tick() call." unless self.reactor_running?

    q = ::Queue.new
    time_start = ::Time.now

    self.next_tick {
    #self.add_timer(0) {
      begin
        res = blk.call
        q << [true, res]
      rescue => e
        q << [false, e]
      end
    }
    
    res = q.shift
    time_elapsed = ::Time.now - time_start
    Wakame.log.debug("EM.barrier: elapsed time for #{blk}: #{time_elapsed} sec (#{$eventmachine_library})") if time_elapsed > 0.05
    if res[0] == false && res[1].is_a?(Exception)
      raise res[1]
    end
    res[1]
  end

end
