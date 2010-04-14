
require 'open4'

class Wakame::Monitor::Service

  class ServiceChecker
    #include Wakame::Packets::Agent
    attr_reader :timer, :svc_id, :interval
    attr_accessor :last_checked_at, :status

    def initialize(svc_id, svc_mon, interval)
      @svc_id = svc_id
      @service_monitor = svc_mon
      @interval = interval
      @status = Wakame::Service::STATUS_OFFLINE
      count = 0
      @timer = Wakame::Monitor::CheckerTimer.new(@interval) {
        self.signal_checker
      }
    end

    def start
      if !@timer.running?
        # Runs checker once for immediate status update.
        signal_checker

        @timer.start
        @service_monitor.send_event(Wakame::Packets::MonitoringStarted.new(@service_monitor.agent, self.svc_id))
        Wakame.log.debug("#{self.class}: Started the checker")
      end
    end

    def stop
      if @timer.running?
        @timer.stop
        @service_monitor.send_event(Wakame::Packets::MonitoringStopped.new(@service_monitor.agent, self.svc_id))
        Wakame.log.debug("#{self.class}: Stopped the checker")
      end
    end

    def check
    end

    protected
    def signal_checker
      EventMachine.defer proc {
        res = begin
                self.last_checked_at = Time.now
                res = self.check
                res 
              rescue => e
                Wakame.log.error("#{self.class}: #{e}")
                Wakame.log.error(e)
                e
              end
        Thread.pass
        res
      }, proc { |res|

        case res
        when Exception
          update_status(Wakame::Service::STATUS_FAIL) 
          @service_monitor.send_event(Wakame::Packets::StatusCheckResult.new(@service_monitor.agent, self.svc_id, Wakame::Service::STATUS_FAIL, res.message))
        when Wakame::Service::STATUS_ONLINE, Wakame::Service::STATUS_OFFLINE
          update_status(res)
          @service_monitor.send_event(Wakame::Packets::StatusCheckResult.new(@service_monitor.agent, self.svc_id, res))
        else
          Wakame.log.error("#{self.class}: Unknown response type from the checker: #{self.svc_id}, ")
        end
      }
    end

    def update_status(new_status)
      prev_status = self.status
      if prev_status != new_status
        self.status = new_status
        @service_monitor.send_event(Wakame::Packets::ServiceStatusChanged.new(@service_monitor.agent, self.svc_id, prev_status, new_status))
      end
    end
  end

  class PidFileChecker < ServiceChecker
    def initialize(svc_id, svc_mon, pidpath, interval)
      super(svc_id, svc_mon, interval)
      @pidpath = pidpath
    end
    
    def check
      return Wakame::Service::STATUS_OFFLINE unless File.exist?(@pidpath)
      #cmdstat = ::Open4.popen4("ps -p \"`cat '#{@pidpath}'`\" > /dev/null"){}
      #cmdstat.exitstatus == 0 ? Wakame::Service::STATUS_ONLINE : Wakame::Service::STATUS_OFFLINE

      cmdres = system("ps -p \"`cat '#{@pidpath}'`\" > /dev/null")
      # system() returns true or false.
      cmdres ? Wakame::Service::STATUS_ONLINE : Wakame::Service::STATUS_OFFLINE
    end
  end

  class CommandChecker < ServiceChecker
    attr_reader :command

    def initialize(svc_id, svc_mon, cmdstr, interval)
      super(svc_id, svc_mon, interval)
      @command = cmdstr
    end

    def check()
      outputs =[]
      cmdstat = ::Open4.popen4(@command) { |pid, stdin, stdout, stderr|
        stdout.each { |l|
          outputs << l
        }
        stderr.each { |l|
          outputs << l
        }
      }
      if outputs.size > 0
        @service_monitor.send_event(Wakame::Packets::MonitoringOutput.new(@service_monitor.agent, self.svc_id, outputs.join('')))
      end

      Wakame.log.debug("#{self.class}: Detected the failed exit status: #{@command}: #{cmdstat}") if cmdstat.exitstatus != 0
      cmdstat.exitstatus == 0 ? Wakame::Service::STATUS_ONLINE : Wakame::Service::STATUS_OFFLINE
    end
  end

  include Wakame::Monitor

  attr_reader :checkers

  def initialize
    @status = Wakame::Service::STATUS_ONLINE
    @checkers = {}
  end

  def send_event(a)
    #Wakame.log.debug("Sending back the event: #{a.class}")
    publish_to('agent_event', a.marshal)
  end

  def find_checker(svc_id)
    @checkers[svc_id]
  end

  def register(svc_id, checker_type, *args)
    chk = @checkers[svc_id]
    if chk
      unregister(svc_id)
    end
    case checker_type.to_sym
    when :pidfile
      chk = PidFileChecker.new(svc_id, self, args[0], args[1])
    when :command
      chk = CommandChecker.new(svc_id, self, args[0], args[1])
    else
      raise "Unsupported checker type: #{checker_type}"
    end
    chk.start
    @checkers[svc_id]=chk
    Wakame.log.info("#{self.class}: Registered service checker for #{svc_id}")
  end

  def unregister(svc_id)
    chk = @checkers[svc_id]
    if chk
      chk.stop
      @checkers.delete(svc_id)
      Wakame.log.info("#{self.class}: Unregistered service checker for #{svc_id}")
    end
  end

  def check_status(svc_id)
    chk = @checkers[svc_id]
    if chk
      chk.status
    else
      raise RuntimeError, "#{self.class}: Specified service id was not found: #{svc_id}"
    end
  end

  def unregister_all
    @checkers.keys.each { |svc_id|
      unregister(svc_id)
    }
  end

  # Reloading the service monitor with new configuration.
  #
  # Example of Hash data in config:
  # config = {
  #   'svc_id_abcde'=>{:type=>:pidfile, :path=>'/var/run/a.pid', :interval=>5},
  #   'svc_id_12345'=>{:type=>:command, :cmdline=>'/bin/ps -ef | grep processname', :interval=>10}
  # }
  def reload(config)
    unregister_all

    reg_single = proc { |svc_id, data|
      data[:interval] ||= 5

      case data[:type]
      when :pidfile
        register(svc_id, data[:type], data[:path], data[:interval])
      when :command
        register(svc_id, data[:type], data[:cmdline], data[:interval])
      else
        raise "Unsupported checker type: #{data[:type]}"
      end
    }
    
    config.each { |svc_id, data|
      if data.is_a?(Array)
        # TODO: Multiple monitors for single service ID
        raise "TODO: Multiple monitors for single service ID"
        data.each { |d|
          reg_single.call(svc_id, d)
        }
      elsif data.is_a?(Hash)
        reg_single.call(svc_id, data)
      else
      end
    }
  end

end
