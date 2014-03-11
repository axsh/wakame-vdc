# encoding: utf-8

Dcmgr::Models::BaseNew.plugin :hook_class_methods

require File.join(Dcmgr::DCMGR_ROOT, "lib/dcmgr/models/hooks/vnet/vnet_hook.rb").sub(/\.rb/, "")
