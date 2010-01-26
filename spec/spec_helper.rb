$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
require 'active_resource'
require 'rack/handler/thin'
require 'dcmgr'

require "#{File.dirname(__FILE__)}/specformat_detail" unless defined? SPECFORMAT

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

  def describe_activeresource_model model_name, user=nil, passwd=nil, port=19393
    user ||= '__test__'
    passwd ||= 'passwd'
    eval(<<END)
    module Test
      class #{model_name.to_s} < ActiveResource::Base
        self.site = 'http://#{user}:#{passwd}@localhost:#{port}/'
        self.format = :json
      end
    end

    return Test::#{model_name.to_s}
END
  end

  def ar_private_class model_name, port=19394
    eval(<<END)
    module Test
      class #{model_name.to_s} < ActiveResource::Base
        self.site = 'http://localhost:#{port}/'
        self.format = :json
      end
    end

    Test::#{model_name.to_s}
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
