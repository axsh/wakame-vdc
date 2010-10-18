#todo:initialier hook
require '../common/lib/models/base_new'
require '../common/lib/models/tag_mapping'
require '../common/lib/models/tag'
require '../common/lib/models/authz'
require '../common/lib/models/user'
require 'pp'

module Sinatra
  module AuthzHelper
    def authorized?(user_id,account_id,authz_class_name)
      tag_authz = Frontend::Models::Tags::Authz
      
      raise 'Undefined authz' unless tag_authz.const_defined?(authz_class_name) 
      authz_class = tag_authz.const_get(authz_class_name)
      
      authz = Frontend::Models::Authz
      has_authz_collections = authz.get_my_authz(user_id,account_id)

      has_authz_collections.each do |row|
        authz = tag_authz.authz_collections.fetch(row.type_id)
        return true if tag_authz.const_get(authz).authz_evaluate?(authz_class)
      end
      false
    end
  end
end