
require 'rubygems'
require 'dcmgr'
require 'rack/handler/webrick'
require 'sinatra'

Dcmgr::Schema.connect 'sqlite:/'
Dcmgr::Schema.create!

require 'dcmgr/web'

module ActiveResourceHelperMethods
  extend self
  
  def runserver
    Thread.new do
      logger = Logger.new('web-test.log')
      logger.level = Logger::DEBUG
      use Rack::CommonLogger, logger
      Rack::Handler::WEBrick.run Dcmgr::Web, :Port => 19393
    end
  end

  def describe_activeresource_model model_name, user=nil, passwd=nil
    user ||= '__test__'
    passwd ||= 'passwd'
    eval(<<END)
    module Test
      class #{model_name.to_s} < ActiveResource::Base
        self.site = 'http://#{user}:#{passwd}@localhost:19393/'
        self.format = :json
      end
    end

    return Test::#{model_name.to_s}
END
  end

  def create_authuser
    @user = User.create(:account=>'__test__', :password=>'passwd')
  end

  def delete_authuser
    @user.delete
  end
end

ActiveResourceHelperMethods.runserver
ActiveResourceHelperMethods.create_authuser

#log = File.new("dcmgr.log", "a")
#STDOUT.reopen(log)
#STDERR.reopen(log)

