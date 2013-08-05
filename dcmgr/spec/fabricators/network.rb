# -*- coding: utf-8 -*-

module DcmgrSpec::Fabricators
  Fabricator(:network, class_name: Dcmgr::Models::Network) do
    account_id TEST_ACCOUNT
    ipv4_network "10.0.0.0"
    prefix 24
    network_mode "securitygroup"
    service_type "std"
    display_name "test network"
  end
end
