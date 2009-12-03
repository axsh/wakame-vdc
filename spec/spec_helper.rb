$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
require 'rack/handler/webrick'
require 'dcmgr'

Dcmgr::Schema.connect 'mysql://localhost/wakame_dcmgr_test?user=dcmgr_test&password=passwd'
Dcmgr::Schema.drop!
Dcmgr::Schema.create!

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
    @account = Account.create(:account=>'__test_account__')
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

