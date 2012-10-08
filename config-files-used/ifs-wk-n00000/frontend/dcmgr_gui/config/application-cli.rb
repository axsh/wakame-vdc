#require File.expand_path('../boot', __FILE__)

#Bundler.require(:default, ENV['RACK_ENV']) if defined?(Bundler)

#require 'app/models/schema'

# Clean up...
#require 'config/initializers/dcmgr_gui'
#@dcmgr_config = YAML::load(ERB.new(IO.read(File.join(Dir.getwd, 'config', 'database.yml'))).result)[ENV['RACK_ENV']]
#Schema.connect "#{@dcmgr_config['adapter']}://#{@dcmgr_config['host']}/#{@dcmgr_config['database']}?user=#{@dcmgr_config['user']}&password=#{@dcmgr_config['password']}"

$LOAD_PATH.unshift File.expand_path('../app/models/', __FILE__)

require 'base_new'
require 'user'
require 'account'

#require 'app/api/auth_server'

module DcmgrGui

  # We need this in order to set 'DcmgrGui::Application.config.secret_token' used in 'user.rb'.
  class ConfigHack
    attr_accessor :secret_token
  end

  # Temp workaround:
  class Application
    def self.config
      @config ||= ConfigHack.new
    end
  end
end
