# -*- coding: utf-8

require 'hijiki'

Hijiki.load(File.expand_path('config/instance_spec.yml', ::Rails.root))
Hijiki.load(File.expand_path('config/load_balancer_spec.yml', ::Rails.root))

Hijiki::DcmgrResource.setup_aliases(:V1203)

Hijiki::RequestAttribute.configure do |c|
  c.service_type = "std"

  c.quota_header do |req_attr|
    a = Account[req_attr.account_id]
    next {} if a.nil?

    Hash[*a.account_quota.map { |i|
           [i.quota_type, i.quota_value]
         }.flatten]
  end
end

ActiveResource::Base.class_eval do
 self.site = DcmgrGui::Application.config.endpoints['dcmgr_site']
end
