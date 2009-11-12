require 'rubygems'
require 'activeresource'

SITE = 'http://user:pass@localhost:9393/'

class Instance < ActiveResource::Base
  self.site = SITE
  self.format = :json
end

# new
instance = Instance.new()

# list

# update
# delete

a = Instance.new
a.save


