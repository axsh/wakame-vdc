# -*- coding: utf-8 -*-

require 'extlib/blank'

module Dolphin
  class Worker
    include Celluloid
    include Dolphin::Util

    def put_event(event)
      logger :debug, "Worker put events #{event}"

      notification_id = event[:notification_id]
      future_event = query_processor.future.put_event(event)

      if notification_id
        future_notification = query_processor.future.get_notification(notification_id)

        if future_event.value && future_notification.value
          notification = future_notification.value
          message_template_id = event[:message_type]

          if !notification['mail'].blank?
            mail = notification['mail']
            messages = event[:messages]
            sender_type = 'email'

            build_params = {}
            build_params["subject"] = mail['subject']
            build_params["to"] = mail['to']
            build_params["cc"] = mail['cc']
            build_params["bcc"] = mail['bcc']
            build_params["message"] = messages['message']

            message = build_message(sender_type, message_template_id, build_params)
            logger :debug, "Send notification from Worker #{message}"

            send_notification(sender_type, message)
          end
        else
          logger :error, "Failed execute query_processor"
        end
      else
        query_processor.future.put_event(event)
      end
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