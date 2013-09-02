# -*- coding: utf-8 -*-

module Dcmgr::Constants
  module HostNode
    HYPERVISOR_XEN_34='xen-3.4'.freeze
    HYPERVISOR_XEN_40='xen-4.0'.freeze
    HYPERVISOR_DUMMY='dummy'.freeze
    HYPERVISOR_KVM='kvm'.freeze
    HYPERVISOR_LXC='lxc'.freeze
    HYPERVISOR_ESXI='esxi'.freeze
    HYPERVISOR_OPENVZ='openvz'.freeze

    ARCH_X86=:x86.to_s.freeze
    ARCH_X86_64=:x86_64.to_s.freeze

    SUPPORTED_ARCH=[ARCH_X86, ARCH_X86_64].freeze
    SUPPORTED_HYPERVISOR=[HYPERVISOR_DUMMY, HYPERVISOR_KVM, HYPERVISOR_LXC, HYPERVISOR_ESXI, HYPERVISOR_OPENVZ].freeze

    STATUS_ONLINE='online'.freeze
    STATUS_OFFLINE='offline'.freeze
  end
end
