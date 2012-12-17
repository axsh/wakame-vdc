# -*- coding: utf-8 -*-

CAPTURE_A_NUMBER = Transform /^\d+$/ do |number|
  number.to_i
end

CAPTURE_A_STRING = Transform /^.+[^\s]$/ do |string|
  string
end

def transform_models_in_string(string)
  string.gsub(/<.[^>]+>/) { |match|
    resource_name, method = match.slice(1,match.size-2).split(".")

    resource = @test_models[resource_name] || raise("Resource #{resource_name} doesn't exist")
    if method.is_a? String
      resource.send(method)
    else
      resource.canonical_uuid
    end
  }
end