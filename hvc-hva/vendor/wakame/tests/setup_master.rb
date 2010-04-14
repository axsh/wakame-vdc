
$:.unshift File.dirname(__FILE__) + '/../lib'

WAKAME_ROOT="#{File.dirname(__FILE__)}/.."
WAKAME_FRAMEWORK_ROOT="#{File.dirname(__FILE__)}/.."
WAKAME_ENV=:StandAlone

require 'rubygems' rescue nil

require 'test/unit'

require 'wakame'
require 'wakame/initializer'
require 'wakame/util'

require 'ext/eventmachine'

#require "#{WAKAME_ROOT}/config/boot"
#Wakame::Bootstrap.boot_agent!

#Wakame::Initializer.run(:process_master)
Wakame::Initializer.run(:setup_load_paths)
Wakame::Initializer.run(:setup_logger)
      

class MockCluster < Wakame::Service::ServiceCluster
end

Wakame.config.cluster_class = 'MockCluster'
