# -*- coding: utf-8 -*-

def create_test_model(model,attributes)
  test_name = attributes.delete(:test_name) || attributes.delete("test_name")

  new_mod = model.create(attributes)
  @test_models[test_name] = new_mod

  new_mod
end

Before do
  @test_models ||= {}
end

After do
  @test_models.values.each { |mod|
    mod.destroy
  }
end

Given /^the following (#{CAPTURE_A_STRING}) exists? in the database$/ do |model_name, attributes|
  mod = Dcmgr::Models.const_get(model_name)

  attributes.hashes.each { |att|
    att["uuid"] = mod.trim_uuid(att["uuid"]) if att["uuid"]
    create_test_model(mod,att)
  }
end
