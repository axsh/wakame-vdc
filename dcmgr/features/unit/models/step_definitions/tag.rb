# -*- coding: utf-8 -*-

Given /^a (NetworkGroup|StorageGroup|HostNodeGroup) (.+) exists with the following mapped resources$/ do |tag_type,tag_name,mapped_names|
  tag_type = Dcmgr::Tags.const_get(tag_type)
  tag = create_test_model(tag_type,{
    :account_id => DEFAULT_ACCOUNT,
    :name => "test group #{tag_name}",
    :test_name => tag_name})
  mapped_names.hashes.each { |test_name|
    resource = @test_models[test_name["mapped_resources"]]

    tag.map_resource(resource)
  }
end
