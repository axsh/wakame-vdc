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
  begin
    @dcmgr_gui_config = YAML::load(IO.read(File.join(Rails.root, 'config', 'dcmgr_gui.yml')))[Rails.env]
  rescue Errno::ENOENT => e
    Rails.logger.error(e.message)
    exit 1
  end
  self.site = @dcmgr_gui_config['dcmgr_site'] 
end
