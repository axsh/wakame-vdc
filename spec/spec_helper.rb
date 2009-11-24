
require 'rubygems'
require 'wakame-dcmgr'
require 'rack/handler/webrick'
require 'sinatra'

Wakame::Dcmgr::Schema.connect 'sqlite:/'
Wakame::Dcmgr::Schema.create!

require 'wakame-dcmgr/web'

module ActiveResourceHelperMethods
  extend self
  
  def runserver
    Thread.new do
      Rack::Handler::WEBrick.run Wakame::Dcmgr::Web, :Port => 19393
    end
  end

  def describe_activeresource_model model_name
    eval(<<END)
    module Test
      class #{model_name.to_s} < ActiveResource::Base
        self.site = 'http://__test__:passwd@localhost:19393/'
        self.format = :json
      end
    end

    return Test::#{model_name.to_s}
END
  end

  def create_authuser
    @user = User.create(:account=>'__test__', :password=>'passwd',
                        :group_id=>1)
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

