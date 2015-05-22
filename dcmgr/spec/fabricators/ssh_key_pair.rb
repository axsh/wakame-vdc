# -*- coding: utf-8 -*-

Fabricator(:ssh_key_pair, class_name: Dcmgr::Models::SshKeyPair) do
  public_key { Dcmgr::Models::SshKeyPair.generate_key_pair('joske')[:public_key] }
end
