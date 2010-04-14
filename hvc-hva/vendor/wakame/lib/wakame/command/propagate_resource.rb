
class Wakame::Command::PropagateResource
  include Wakame::Command
  include Wakame

  command_name 'propagate_resource'

  def run
    resname = @options["resource"]

    resobj = Service::Resource.find(Service::Resource.id(resname))
    if resobj.nil?
      raise "Unknown Resource: #{resname}" 
    end

    cloud_host_id = @options["cloud_host_id"]
    if cloud_host_id.nil?
      cloud_host = service_cluster.add_cloud_host { |h|
        if @options["vm_attr"].is_a? Hash
          h.vm_attr = @options["vm_attr"]
        end
      }
    else
      cloud_host = Service::CloudHost.find(cloud_host_id) || raise("Specified host was not found: #{cloud_host_id}")
      raise "Same resouce type is already assigned: #{resobj.class} on #{cloud_host_id}" if cloud_host.has_resource_type?(resobj)
    end
    

    num = options["number"] || 1
    raise "Invalid format of number: #{num}" unless /^(\d+)$/ =~ num.to_s
    num = num.to_i

    if num < 1 || resobj.max_instances < service_cluster.instance_count(resobj) + num
      raise "The number must be between 1 and #{resobj.max_instances - service_cluster.instance_count(resobj)} (max limit: #{resobj.max_instances})"
    end

    num.times {
      trigger_action(Wakame::Actions::PropagateResource.new(resobj, cloud_host.id))
    }

  end
end
