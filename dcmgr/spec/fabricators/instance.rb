# -*- coding: utf-8 -*-

module DcmgrSpec::Fabricators
  Fabricator(:instance, class_name: Dcmgr::Models::Instance) do
    account_id TEST_ACCOUNT
    hypervisor "openvz"
  end
end
