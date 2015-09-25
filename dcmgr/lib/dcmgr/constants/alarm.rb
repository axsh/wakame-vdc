# -*- coding: utf-8 -*-

module Dcmgr::Constants
  module Alarm
    LOG_METRICS = [
      'log'
    ].freeze

    SUPPORT_METRICS = (LOG_METRICS).freeze

    SUPPORT_COMPARISON_OPERATOR = {
      'ge' => :>=,
      'gt' => :>,
      'le' => :<=,
      'lt' => :<,
    }.freeze

    SUPPORT_NOTIFICATION_TYPE = [
      'dolphin'
    ].freeze

    LOG_NOTIFICATION_ACTIONS = [
      'alarm',
      'insufficient_data'
    ].freeze

  end
end
