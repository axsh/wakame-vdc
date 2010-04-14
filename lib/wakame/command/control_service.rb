class Wakame::Command::ControlService
  include Wakame::Command
  include Wakame

  command_name 'control_service'

  def run
    num = @options["number"] || 1
    raise "Invalid format of number: #{num}" unless /^(\d+)$/ =~ num.to_s
    num = num.to_i

    resname = @options["resource"]
    resobj = Service::Resource.find(Service::Resource.id(resname))

    if num < 1 || resobj.max_instances < num 
      raise "The number must be between 1 and #{resobj.max_instances - service_cluster.instance_count(resobj)} (max limit: #{resobj.max_instances})"
    end

    if service_cluster.instance_count(resobj) < num
      num = (num - service_cluster.instance_count(resobj)).to_i
      cloud_host_id = nil
      refsvc = service_cluster.find_service(@options["service_id"])
      if refsvc.nil?
       raise("Unknown ServiceInstance ID: #{@options["service_id"]}")
      end
      trigger_action{|action|
        num.times{
          action.trigger_action(Wakame::Actions::PropagateService.new(refsvc, cloud_host_id))
        }
      }
    else
      num = (service_cluster.instance_count(resobj) - num).to_i
      refsvc = service_cluster.each_instance(resobj)
      do_terminate = true
      c = 1
      refsvc.reverse_each {|svc|
        trigger_action(Wakame::Actions::StopService.new(svc, do_terminate))
        c += 1
        break if c > num
      }
    end
  end
end
