# -*- coding: utf-8 -*-

require 'metric_libs/version'

module MetricLibs
  autoload :MetricValue, 'metric_libs/metric_value'
  autoload :TimeSeries, 'metric_libs/time_series'
  autoload :VERSION, 'metric_libs/version'
  autoload :AlarmManager, 'metric_libs/alarm_manager'
  autoload :Alarm, 'metric_libs/alarm'
  autoload :Timer, 'metric_libs/timer'

  module Constants
    autoload :Alarm, 'metric_libs/constants/alarm'
  end
end
