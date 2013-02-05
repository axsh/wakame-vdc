# -*- coding: utf-8 -*-

Given /^the following configuration is placed in dcmgr.conf$/ do |conf|
  # Replace resources' test names by their actual uuids
  parsed_conf = conf.gsub(/<.[^>]+>/) { |match|
    resource_name, method = match.slice(1,match.size-2).split(".")

    resource = @test_models[resource_name] || raise("Resource #{resource_name} doesn't exist")
    if method.is_a? String
      resource.send(method)
    else
      resource.canonical_uuid
    end
  }

  Dcmgr.conf.parse_dsl do |me|
    me.instance_eval(parsed_conf)
  end

  @dcmgr_conf_errors = []
  Dcmgr::Configuration.walk_tree(Dcmgr.conf) do |c|
    c.validate(@dcmgr_conf_errors)
  end
end
