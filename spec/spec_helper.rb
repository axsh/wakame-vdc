$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
require 'active_resource'
require 'rack/handler/thin'
require 'dcmgr'
require 'dcmgr/certificated_active_resource'

require "#{File.dirname(__FILE__)}/specformat_detail" unless defined? SPECFORMAT

# generate 100 ip
ips = []; 100.times{|i| ips << ["00:16:%d" % i, "192.168.11.#{i + 200}"]}
Dcmgr.assign_ips = Hash[*ips.flatten]

module ActiveResourceHelperMethods
  extend self
  
  def runserver(mode=:public)
    Thread.new do
      if mode == :public
        Rack::Handler::Thin.run Dcmgr::PublicWeb, :Port => 19393
      else
        Rack::Handler::Thin.run Dcmgr::PrivateWeb, :Port => 19394
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
      class #{model_name} < Dcmgr::CertificatedActiveResource
        self.site = "#{site}"
        self.format = :json
        self.user_uuid = '#{user_uuid}'
      end
    end
    Test::#{model_name}
    END
  end

  def ar_class_fsuser model_name, opts={}
    user = opts[:user] || '__test__'
    passwd = opts[:password] || 'passwd'
    port = opts[:port] || 19393

    site = "http://#{user}:#{passwd}@localhost:#{port}/"

    eval(<<-END)
    module Test
      class #{model_name} < ActiveResource::Base
        self.site = "#{site}"
        self.format = :json
      end
    end
    Test::#{model_name}
    END
  end

  def reset_db
    Dcmgr::Schema.drop!
    Dcmgr::Schema.create!
    Dcmgr::Schema.load_data File.dirname(__FILE__) + '/../fixtures/sample_data'
  end
end

Dcmgr::Schema.connect 'mysql://localhost/wakame_dcmgr_test?user=dcmgr_test&password=passwd'
ActiveResourceHelperMethods.reset_db
ActiveResourceHelperMethods.runserver

