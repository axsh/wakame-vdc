# -*- coding: utf-8 -*-

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'hijiki'

Hijiki.load(File.join(File.dirname(__FILE__), '..', '..', '..', 'frontend', 'dcmgr_gui', 'config', 'instance_spec.yml'))

Hijiki::DcmgrResource.setup_aliases(:V1203)

Hijiki::RequestAttribute.configure do |c|
  c.service_type = "std"
  c.quota_header do |req_attr|
    {}
  end
end

Thread.current[:hijiki_request_attribute] = Hijiki::RequestAttribute.new('a-shpoolxx')

ActiveResource::Base.class_eval do
  begin
    @dcmgr_gui_config = YAML::load(IO.read(File.join(File.dirname(__FILE__), '..', '..', '..', 'frontend', 'dcmgr_gui', 'config', 'dcmgr_gui.yml')))['development']
  rescue Errno::ENOENT => e
    p e.message
    exit 1
  end
  self.site = @dcmgr_gui_config['dcmgr_site']
end

require File.join(File.dirname(__FILE__) + '/api/ts_base.rb')

['api'].each do |l|
  Dir.glob(File.join(File.dirname(__FILE__) + "/#{l}", '*.rb')).each do |f|
    require f
  end
end

