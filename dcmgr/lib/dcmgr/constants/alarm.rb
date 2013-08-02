# -*- coding: utf-8 -*-

module Dcmgr::Constants
  module Alarm
    RESOURCE_METRICS = [
      'cpu.usage',
      'disk.usage',
      'memory.usage',
    ].freeze

    LOG_METRICS = [
      'log'
    ].freeze

    SUPPORT_METRICS = (RESOURCE_METRICS + LOG_METRICS).freeze

    SUPPORT_COMPARISON_OPERATOR = {
      'ge' => :>=,
      'gt' => :>,
      'le' => :<=,
      'lt' => :<,
    }.freeze

    SUPPORT_NOTIFICATION_TYPE = [
      'dolphin'
    ].freeze


    RESOURCE_NOTIFICATION_ACTIONS = [
      'ok',
      'alarm',
      'insufficient_data'
    ].freeze

    LOG_NOTIFICATION_ACTIONS = [
      'alarm',
      'insufficient_data'
    ].freeze

  end
end
