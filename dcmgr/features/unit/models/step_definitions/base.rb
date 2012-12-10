# -*- coding: utf-8 -*-

def create_test_model(model,attributes)
  test_name = attributes.delete(:test_name) || attributes.delete("test_name")

  new_mod = model.create(attributes)
  @test_models[test_name] = new_mod

  new_mod
end

DEFAULT_ACCOUNT="a-shpoolxx"

Before do
  @test_models ||= {}
end

After do
  @test_models.values.each { |mod|
    mod.destroy
  }
end


Given /^the following (.+) exists? in the database$/ do |model_name, attributes|
  mod = Dcmgr::Models.const_get(model_name)

  attributes.hashes.each { |att|
    att["uuid"] = mod.trim_uuid(att["uuid"]) if att["uuid"]
    create_test_model(mod,att)
  }
end

Given /^a (NetworkGroup|StorageGroup|HostNodeGroup) (.+) exists with the following mapped resources$/ do |tag_type,tag_name,mapped_ids|
  tag_type = Dcmgr::Tags.const_get(tag_type)
  tag = create_test_model(tag_type,{
    :account_id => DEFAULT_ACCOUNT,
    :name => "test group #{tag_name}",
    :test_name => tag_name})
  mapped_ids.hashes.each { |test_name|
    resource = @test_models[test_name["mapped_resources"]]

    tag.map_resource(resource)
  }
end

Given /^Network (.+) has the following dhcp range$/ do |test_name,ranges|
  network = @test_models[test_name]
  raise "#{test_name} is not a Network" unless network.is_a?(Dcmgr::Models::Network)

  range_begin = ranges.hashes[0]["range_begin"]
  range_end = ranges.hashes[0]["range_end"]

  network.add_ipv4_dynamic_range(range_begin,range_end)
end
