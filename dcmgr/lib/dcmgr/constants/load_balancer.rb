# -*- coding: utf-8 -*-

module Dcmgr::Constants::LoadBalancer
  PUBLIC_DEVICE_INDEX = 0.freeze
  MANAGEMENT_DEVICE_INDEX = 1.freeze
  SERVICE_TYPE = 'lb'.freeze

  PROTOCOLS = ['http', 'tcp'].freeze
  SECURE_PROTOCOLS = ['https', 'ssl'].freeze
  SUPPORTED_PROTOCOLS = (PROTOCOLS + SECURE_PROTOCOLS).freeze
  SUPPORTED_INSTANCE_PROTOCOLS = PROTOCOLS

  STATE_RUNNING = 'running'.freeze
  STATE_TERMINATED = 'terminated'.freeze
end
