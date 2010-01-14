$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
require 'active_resource'
require 'rack/handler/webrick'
require 'dcmgr'

Dcmgr::Schema.connect 'mysql://localhost/wakame_dcmgr_test?user=dcmgr_test&password=passwd'
Dcmgr::Schema.drop!
Dcmgr::Schema.create!

module ActiveResourceHelperMethods
  extend self
  
  def runserver
    Thread.new do
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
    $spec_user = User.create(:name=>'__test__', :password=>'passwd')
    $spec_account = Account.create(:name=>'__test_account__')
  end

  def delete_authuser
    $spec_user.delete
  end
end

unless defined? DISABLE_TEST_SERVER
  ActiveResourceHelperMethods.runserver
end
ActiveResourceHelperMethods.create_authuser
