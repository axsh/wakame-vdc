
class Wakame::Command::DeployApplication
  include Wakame::Command
  include Wakame::Service

  command_name 'deploy_application'

  def run
    raise "Invalid application name: \"#{params['app_name']}\"" if params['app_name'].nil? || params['app_name'] !~ /\A[\w\-\.\@]+\Z/
    if Wakame::Models::ApplicationRepository.find(:app_name=>params['app_name']) == nil
      raise "The name of application is not registered: #{params['app_name']}"
    end

    
    trigger_action(Wakame::Actions::DeployApplication.new(params['app_name']))
  end

end
