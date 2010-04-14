
class Wakame::Command::ReloadService
  include Wakame::Command

  command_name 'reload_service'

  def run
    svc = service_cluster.find_service(options['service_id'])
    trigger_action(Wakame::Actions::ReloadService.new(svc))
  end
end
