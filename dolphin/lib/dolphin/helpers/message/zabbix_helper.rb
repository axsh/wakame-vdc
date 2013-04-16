# -*- coding: utf-8 -*-

module Dolphin::Helpers::Message
  module ZabbixHelper
    def trigger_value_text(trigger_value)
      case trigger_value
        when '0'
          '正常'
        when '1'
          '異常'
        else
          '不明'
      end
    end
  end
end