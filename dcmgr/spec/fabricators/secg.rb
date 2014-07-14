# -*- coding: utf-8 -*-

module DcmgrSpec::Fabricators
  Fabricator(:secg, class_name: Dcmgr::Models::SecurityGroup) do
    account_id TEST_ACCOUNT
  end
end
