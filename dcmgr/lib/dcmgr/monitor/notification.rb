# -*- coding:utf-8 -*-
require 'dolphin_client'

module Dcmgr
  module Monitor
    class Notification
      include Dcmgr::Logger

      class << self
        def build_message(action, value)
          raise ArgumentError unless action.is_a?(Hash)
          raise ArgumentError unless value.is_a?(Hash)
          h = {
            :notification_id => action["notification_id"],
            :message_type => action["notification_message_type"],
            :params => {
              :state => value["state"],
              :metric_name => value["metric_name"],
              :resource_id => value["resource_id"],
              :ipaddr => value["ipaddr"]
            }
          }
        end

        def send(value)
          raise ArgumentError unless value.is_a?(Hash)
          DolphinClient.domain = Dcmgr.conf.dolphin_server_uri
          DolphinClient::Event.post(value)
        end
      end        
    end
  end
end
