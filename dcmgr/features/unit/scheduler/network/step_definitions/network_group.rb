# -*- coding: utf-8 -*-

require "yaml"

When /^an instance (#{CAPTURE_A_STRING}) is scheduled with no vifs parameter$/ do |inst_name|
  create_test_model(Dcmgr::Models::Instance,{:test_name=>inst_name,:account_id=>DEFAULT_ACCOUNT,:request_params=>{}})
  @scheduled_instance = @test_models[inst_name]

  svc_type = Dcmgr::Scheduler.service_type(@scheduled_instance)
  svc_type.network.schedule(@scheduled_instance)
end

When /^an instance (#{CAPTURE_A_STRING}) is scheduled with the following vifs parameter$/ do |inst_name, request_params|
  request_params = transform_models_in_string(request_params)
  vifs_param = { "vifs" => eval(request_params) }

  create_test_model(Dcmgr::Models::Instance,{:test_name=>inst_name,:account_id=>DEFAULT_ACCOUNT,:request_params=>vifs_param})
  @scheduled_instance = @test_models[inst_name]

  svc_type = Dcmgr::Scheduler.service_type(@scheduled_instance)
  svc_type.network.schedule(@scheduled_instance)
end

Then /^instance (#{CAPTURE_A_STRING}) should have (#{CAPTURE_A_NUMBER}) vnics? in total$/ do |instance_name,vnics_amount|
  inst = @test_models[instance_name]
  real_vnics_amount = inst.network_vif_dataset.count

  raise "Instance #{instance_name} has #{real_vnics_amount} vnics and should have #{vnics_amount}" unless real_vnics_amount == vnics_amount
end

Then /^instance (#{CAPTURE_A_STRING}) should have (#{CAPTURE_A_NUMBER}) vnics? in a network from group (#{CAPTURE_A_STRING})$/ do |instance_name,vnics_amount,nw_group|
  inst = @test_models[instance_name]
  nwg = @test_models[nw_group]

  vnic_counter = 0
  inst.network_vif.each { |vnic|
    vnic_counter += 1 if nwg.mapped_resources.member?(vnic.network)
  }

  raise "Instance #{instance_name} has #{vnic_counter} vnics in a network from #{nw_group} but should have #{vnics_amount}" unless vnic_counter == vnics_amount
end

Then /^instance (#{CAPTURE_A_STRING}) should have (#{CAPTURE_A_NUMBER}) vnics? in network (#{CAPTURE_A_STRING})$/ do |instance_name, vnics_amount, nw_name|
  inst = @test_models[instance_name]
  nw = @test_models[nw_name]

  vnic_counter = 0
  inst.network_vif.each { |vnic|
    vnic_counter += 1 if vnic.network == nw
  }

  raise "Instance #{instance_name} has #{vnic_counter} vnics in network #{nw_name} but should have #{vnics_amount}" unless vnic_counter == vnics_amount
end

Then /^instance (#{CAPTURE_A_STRING}) should have (#{CAPTURE_A_NUMBER}) vnics? not in any network$/ do |instance_name, vnics_amount|
  inst = @test_models[instance_name]

  vnic_counter = 0
  inst.network_vif.each { |vnic|
    vnic_counter += 1 if vnic.network.nil?
  }

  raise "Instance #{instance_name} has #{vnic_counter} vnics not in any network but should have #{vnics_amount}" unless vnic_counter == vnics_amount
end
