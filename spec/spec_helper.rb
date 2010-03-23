$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'active_resource'
require 'rack/handler/thin'
require 'dcmgr'
require "#{File.dirname(__FILE__)}/../client/client"

require "#{File.dirname(__FILE__)}/specformat_detail" unless defined? SPECFORMAT

module ActiveResourceHelperMethods
  extend self
  
  def runserver(mode=:public)
    Thread.new do
      if mode == :public
        puts "start public server"
        Rack::Handler::Thin.run Dcmgr::Web::Public, :Port => 19393
      else
        puts "start private server"
        Rack::Handler::Thin.run Dcmgr::Web::Private, :Port => 19394
      end
    end
  end

  def ar_class model_name, opts={}
    username = opts[:user] || '__test__'
    user_uuid = opts[:uuid]
    unless user_uuid
      user = User.find(:name=>username)
      user_uuid = user.uuid if user
    end

    raise "user unknown: #{user}" unless user_uuid
    
    port = opts[:port] || 19393
    private_mode = if opts.key?(:private) then opts[:private] else false end
    site = "http://localhost:#{port}/"

    eval(<<-END)
    module Test
      class #{model_name} < Dcmgr::Client::CertificatedActiveResource
        self.site = "#{site}"
        self.format = :json
        self.user_uuid = '#{user_uuid}'
      end
    end
    Test::#{model_name}
    END
  end

  def ar_class_with_basicauth model_name, opts={}
    user = opts[:user] || '__test__'
    passwd = opts[:password] || 'passwd'
    private_mode = opts[:private]
    port = opts[:port] || (private_mode and 19394) || 19393

    site = "http://#{user}:#{passwd}@localhost:#{port}/"

    eval(<<-END)
    module Test2
      class #{model_name} < ActiveResource::Base
        self.site = "#{site}"
        self.format = :json
      end
    end
    Test2::#{model_name}
    END
  end

  def reset_db
    Dcmgr::Schema.drop!
    Dcmgr::Schema.create!
    Dcmgr::Schema.load_data File.dirname(__FILE__) + '/../fixtures/sample_data'
  end
end

Dcmgr::Schema.connect 'mysql://localhost/wakame_dcmgr_test?user=dcmgr_test&password=passwd'

Dcmgr.fsuser_auth_type = :ip
Dcmgr.fsuser_auth_users = {"gui"=>"127.0.0.1"}

ActiveResourceHelperMethods.reset_db
ActiveResourceHelperMethods.runserver
sleep 1.0
