class Wakame::Command::StartService
  include Wakame::Command

  command_name 'start_service'

  def run
    svc = service_cluster.find_service(params[:service_id])
    if svc.nil?
      raise "Unknown Service ID: #{params[:service_id]}"
    end

    trigger_action(Wakame::Actions::StartService.new(svc))
  end
end
