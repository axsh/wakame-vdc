# -*- coding: utf-8 -*-

require "yaml"

When /^an instance (.+) is scheduled with no vifs parameter$/ do |inst_name|
  create_test_model(Dcmgr::Models::Instance,{:test_name=>inst_name,:account_id=>DEFAULT_ACCOUNT,:request_params=>{}})
  @scheduled_instance = @test_models[inst_name]

  svc_type = Dcmgr::Scheduler.service_type(@scheduled_instance)
  svc_type.network.schedule(@scheduled_instance)
end

When /^an instance (.+) is scheduled with the following vifs parameter$/ do |inst_name, request_params|
  vifs_param = { "vifs" => eval(request_params) }

  # Translate the test names into actual uuids
  vifs_param["vifs"].each {|k,v|
    if v.has_key?("network")
      real_mod = @test_models[v["network"]] || raise("Unknown network: #{v["network"]}")

      v["network"] = real_mod.canonical_uuid
    end
  }

  create_test_model(Dcmgr::Models::Instance,{:test_name=>inst_name,:account_id=>DEFAULT_ACCOUNT,:request_params=>vifs_param})
  @scheduled_instance = @test_models[inst_name]

  svc_type = Dcmgr::Scheduler.service_type(@scheduled_instance)
  svc_type.network.schedule(@scheduled_instance)
end

Then /^instance (.+) should have (\d+) vnics? in total$/ do |instance_name,vnics_amount|
  inst = @test_models[instance_name]
  real_vnics_amount = inst.network_vif_dataset.count

  raise "Instance #{instance_name} has #{real_vnics_amount} vnics and should have #{vnics_amount}" unless real_vnics_amount == vnics_amount.to_i
end

Then /^instance (.+) should have (\d+) vnics? in a network from group (.+)$/ do |instance_name,vnics_amount,nw_group|
  inst = @test_models[instance_name]
  nwg = @test_models[nw_group]

  vnic_counter = 0
  inst.network_vif.each { |vnic|
    vnic_counter += 1 if nwg.mapped_resources.member?(vnic.network)
  }

  raise "Instance #{instance_name} has #{vnic_counter} vnics in a network from #{nw_group} but should have #{vnics_amount}" unless vnic_counter == vnics_amount.to_i
end

