class Wakame::Actor::Xen
  include Wakame::Actor

  # for Amazon EC2
  def initialize
    @return_value = nil
  end

  def run_instance(options)
    sleep 10
    Wakame.log.debug("#{self.class}.run_instance()")
    #Wakame::Util.exec("./home/xen/bin/domu-run-instance.sh #{options["image"]} #{options["instance_uuid"]}")
    Wakame::Util.exec("./home/xen/bin/domu-run-instance.sh centos5.4-i386-1part-aio-4gb-2009121801 #{options["instance_uuid"]} #{options["instance_mac"]}")
  end

  def terminate_instance(options)
    sleep 10
    Wakame.log.debug("#{self.class}.terminate_instance()")
    Wakame::Util.exec("./home/xen/bin/domu-terminate-instances.sh #{options["instance_uuid"]}")
  end

  def describe_instance
    Wakame.log.debug("#{self.class}.describe_instance()")
    command ="./home/xen/bin/domu-describe-instances.sh"
    outputs = []
    Wakame.log.debug("#{self}.exec(#{command})")
    cmdstat = ::Open4.popen4(command) { |pid, stdin, stdout, stderr|
      stdout.each { |l|
        outputs << l
      }
      stderr.each { |l|
        outputs << l
      }
    }
    res = outputs.join('')
    Wakame.log.debug(res)
    raise "Command Failed (exit=#{cmdstat.exitstatus}): #{command}" unless cmdstat.exitstatus == 0
    @return_value = res
  end
end
