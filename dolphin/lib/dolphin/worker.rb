# -*- coding: utf-8 -*-

require 'extlib/blank'

module Dolphin
  class Worker
    include Celluloid
    include Dolphin::Util

    def put_event(event_object)
      logger :info, "Worker put events #{event_object}"

      notification_id = event_object[:notification_id]
      future_event = query_processor.future.put_event(event_object)

      if notification_id
        future_notification = query_processor.future.get_notification(notification_id)
        notification = future_notification.value
        event = future_event.value

        if notification.nil?
          logger :error, "Not found notification_id:#{event_object[:notification_id]}"
          return
        end

        if event && notification

          message_template_id = event_object[:message_type]

          if !notification['mail'].blank?
            mail = notification['mail']
            sender_type = 'email'

            build_params = {}
            build_params["subject"] = mail['subject']
            build_params["to"] = mail['to']
            build_params["cc"] = mail['cc']
            build_params["bcc"] = mail['bcc']
            build_params["messages"] = event_object[:messages]

            message = build_message(sender_type, message_template_id, build_params)
            if message.nil?
              logger :error, "Failed to notify because notifification object not found."
              return false
            end

            logger :info, "Send notification from Worker #{message}"
            send_notification(sender_type, message)
          end
        else
          logger :error, "Failed execute query_processor"
          return false
        end
      else
        query_processor.future.put_event(event_object)
      end
    end

    def get_event(params)
      query_processor.future.get_event(params)
    end

    def put_notification(notification)
      query_processor.future.put_notification(notification)
    end

    private
    def query_processor
      Celluloid::Actor[:query_processors]
    end

    def sender(type)
      Celluloid::Actor[type]
    end

    def send_notification(type, message)
      case type
        when 'email'
          sender(:mail_senders).notify(message)
      end
    end

    def build_message(type, template_id, params)
      case type
        when 'email'
        MessageBuilder::Mail.new.build(template_id, params)
      end
    end
  end
end
