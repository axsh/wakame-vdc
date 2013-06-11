# -*- coding: utf-8 -*-

require 'extlib/blank'

module Dolphin
  class Worker
    include Celluloid
    include Dolphin::Util

    def put_event(event_object)
      logger :info, "Worker put events #{event_object}"

      notification_id = event_object[:notification_id]
      message_template_id = event_object[:message_type]

      future_event = query_processor.future.put_event(event_object)

      # if notification_id not exists, doesn't send notification.
      unless notification_id
        return SuccessObject.new
      end

      future_notification = query_processor.future.get_notification(notification_id)

      # synchronized
      notifications = future_notification.value
      future_event.value

      if notifications.nil?
        log_message = "Not found notification: #{event_object[:notification_id]}"
        logger :error, log_message
        return FailureObject.new(log_message)
      end

      if query_processor_failed?(notifications)
        return FailureObject.new('Failed to get notifications')
      end

      notifications.each do |sender_type, values|
        if values.blank?
          logger :info, "Skip to notify message because notifications was blank."
          next
        end

        unless Sender::TYPES.include? sender_type
          log_message = "Not found sender #{sender_type}"
          logger :error, log_message
          # Does not do response to Request Handler.
          next
        end

        build_params = {}
        # TODO: Plugin
        case sender_type
          when 'email'
            build_params["to"] = values['to']
            build_params["cc"] = values['cc']
            build_params["bcc"] = values['bcc']
            build_params["messages"] = event_object[:messages]
        end

        message = build_message(sender_type, message_template_id, build_params)

        if message.nil?
          log_message = "Failed to build message: #{message}"
          logger :error, log_message
          # Does not do response to Request Handler.
          next
        end

        logger :info, "Send notification from Worker #{message}"

        begin
          send_notification(sender_type, message)
        rescue => e
          logger :error, e
          # Does not do response to Request Handler.
          next
        end
      end

      SuccessObject.new
    end

    def get_event(params)
      event = query_processor.get_event(params)
      if query_processor_failed?(event)
       return FailureObject.new('Failed to get events')
     end
      SuccessObject.new(event)
    end

    def get_notification(notification)
      notification_id = notification[:id]
      notification = query_processor.get_notification(notification_id)
      if query_processor_failed?(notification)
        return FailureObject.new('Failed to get notification')
      end
      SuccessObject.new(notification)
    end

    def put_notification(notification)
      notification = query_processor.put_notification(notification)
      if query_processor_failed?(notification)
        return FailureObject.new('Failed to put notification')
      end
      SuccessObject.new(notification)
    end

    def delete_notification(notification)
      notification = query_processor.delete_notification(notification)
      if query_processor_failed?(notification)
        return FailureObject.new('Failed to delete notification')
      end
      SuccessObject.new(notification)
    end

    private
    def query_processor_failed?(response_data)
      response_data === FALSE
    end

    def query_processor
      Celluloid::Actor[:query_processors]
    end

    def sender(type)
      Celluloid::Actor[type]
    end

    def send_notification(type, log_message)
      case type
        when 'email'
          sender(:mail_senders).notify(log_message)
        else
          raise "Unsuppoted sender type: #{type}"
      end
    end

    def build_message(type, template_id, params)
      case type
        when 'email'
          MessageBuilder::Mail.new.build(template_id, params)
        else
          nil
      end
    end
  end
end
