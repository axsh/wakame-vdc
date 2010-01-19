$:.unshift 'lib'
require "#{File.dirname(__FILE__)}/../../vendor/gems/environment"

require 'active_resource'

URL = 'http://__test__:passwd@localhost:3000'

class Instance < ActiveResource::Base
  self.site = URL
  self.format = :json
end
