require 'client/certificated_active_resource'

URL = 'http://__test__:passwd@localhost:3000'
USER_UUID = 'U-XXXXXXXX'

# Custom Active Resource Class, add request header parameter user_uuid
#
# sample:
# class A < Dcmgr::CertificatedActiveResource
#   self.user_uuid = 'abc'
#   self.site = xxxx
# end

class Base < CertificatedActiveResource
  self.site = URL
  self.user_uuid = USER_UUID
end

class Instance < Base; end
class FrontendServiceUser < Base; end
      
class Account < Base; end
class User < Base; end
class KeyPair < Base; end
      
class NameTag < Base; end
class AuthTag < Base; end
class TagAttribute < Base; end
      
class Instance < Base; end
class PhysicalHost < Base; end
      
class ImageStorage < Base; end
class ImageStorageHost < Base; end
      
class LocationGroup < Base; end
