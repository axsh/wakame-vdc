$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
require 'active_resource'
require 'rack/handler/thin'
require 'dcmgr'

require "#{File.dirname(__FILE__)}/specformat_detail" unless defined? SPECFORMAT

Dcmgr.assign_ips = {
  '00:16:3E:49:23:C9' => '192.168.11.201',
  '00:16:3E:49:23:CA' => '192.168.11.202',
  '00:16:3E:49:23:CB' => '192.168.11.203',
  '00:16:3E:49:23:CC' => '192.168.11.204',
  '00:16:3E:49:23:CD' => '192.168.11.205',
  '00:16:3E:49:23:CE' => '192.168.11.206',
  '00:16:3E:49:23:CF' => '192.168.11.207',
  '00:16:3E:49:23:D0' => '192.168.11.208',
  '00:16:3E:49:23:D1' => '192.168.11.209',
  '00:16:3E:49:23:D2' => '192.168.11.210',
}

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
    user = opts[:user] || '__test__'
    passwd = opts[:password] || 'passwd'
    port = opts[:port] || 19393
    private_mode = if opts.key?(:private) then opts[:private] else false end

    if private_mode
      site = "http://localhost:19394/"
    else
      site = "http://#{user}:#{passwd}@localhost:#{port}/"
    end
    
    eval(<<END)
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

