class Wakame::Command::StopService
  include Wakame::Command

  command_name 'stop_service'

  # terminate
  # service_id or resource_name
  def run
    do_terminate = true
    if options['do_terminate'] == 'false'
      do_terminate = false
    end

    if options['service_id']
      svc_inst = service_cluster.find_service(options['service_id'])
      trigger_action(Wakame::Actions::StopService.new(svc_inst, do_terminate))
    elsif options['resource_name']
      # resource_name is expected to be set two types of name: the class name inherited from Resource or the module name.
      # The user can stop set of service instances as per the filterring rule of each_instace() method.
      # For example: if you pass "HttpServer" module name to the resource_name option, all the services include "HttpServer" module
      # will be stopped in one shot.
      filter_type = Wakame::Util.build_const(options['resource_name'])
      if (filter_type.is_a?(Module) && !filter_type.is_a?(Class)) ||
          (filter_type.is_a?(Class) && filter_type < Wakame::Service::Resource)
        # They are valid filter types.
      else
        raise "Invalid names as resource name: #{options['resource_name']}"
      end
      service_cluster.each_instance(filter_type).each { |svc_inst|
        trigger_action(Wakame::Actions::StopService.new(svc_inst, do_terminate))
      }
    else
      raise "Could not find valid service_id or resource_name parameter."
    end

  end
end
