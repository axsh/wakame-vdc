# -*- coding: utf-8 -*-

module Dcmgr::Constants::VirtualDataCenterSpec
  VDCS_PARAMS_STRING = 'vdc_name'.freeze
  VDCS_PARAMS_HASH = ['vdc_spec', 'instance_spec'].freeze
  VDCS_PARAMS = [VDCS_PARAMS_STRING, VDCS_PARAMS_HASH].flatten.freeze

  VDCS_INSTANCE_PARAMS_STRING = ['host_node_group', 'hypervisor'].freeze
  VDCS_INSTANCE_PARAMS_INT = ['cpu_cores', 'memory_size'].freeze
  VDCS_INSTANCE_PARAMS = [VDCS_INSTANCE_PARAMS_STRING, VDCS_INSTANCE_PARAMS_INT].flatten.freeze

  VDCS_SPEC_PARAMS = ['instance_spec', 'image_id'].freeze
end
