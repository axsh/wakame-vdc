# -*- coding: utf-8 -*-

Fabricator(:image, class_name: Dcmgr::Models::Image) do
  os_type Dcmgr::Constants::Image::OS_TYPE_LINUX
  arch Dcmgr::Constants::HostNode::ARCH_X86_64
  boot_dev_type Dcmgr::Constants::Image::BOOT_DEV_LOCAL
end
