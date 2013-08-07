# -*- coding:utf-8 -*-

module MetricLibs::Constants
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

    SUPPORT_STATISTICS = [
      'avg'
    ].freeze

    SUPPORT_COMPARISON_OPERATOR = {
      'ge' => :>=,
      'gt' => :>,
      'le' => :<=,
      'lt' => :<,
    }.freeze

    INSUFFICIENT_DATA_STATE = 'insufficient_data_state'
    OK_STATE = 'ok_state'
    ALARM_STATE = 'alarm_state'
  end
end
