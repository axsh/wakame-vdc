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

    INSUFFICIENT_DATA_STATE = 'insufficient_data'
    OK_STATE = 'ok'
    ALARM_STATE = 'alarm'

    METRICS_ERROR_COUNT = {
      'cpu.usage' => 5,
      'memory.usage' => 5,
      'log' => 5
    }.freeze
  end
end
