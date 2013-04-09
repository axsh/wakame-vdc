# -*- coding: utf-8 -*-

require 'celluloid'
require 'action_mailer'

module Dolphin

  module Sender
    TYPES = ['email'].freeze

    TYPE = [:mail_senders].freeze

    case Dolphin.settings['mail']['type']
      when 'file'
        ActionMailer::Base.delivery_method = :file
        ActionMailer::Base.raise_delivery_errors = true
        ActionMailer::Base.file_settings = {
          :location => File.join(Dolphin.root_path, 'tmp/mails')
        }
      when 'tls-mail'
        ActionMailer::Base.delivery_method = :smtp
        ActionMailer::Base.smtp_settings = {
          address: Dolphin.settings['mail']['host'],
          port: Dolphin.settings['mail']['port'],
          user_name: Dolphin.settings['mail']['user_name'],
          password: Dolphin.settings['mail']['password'],
          authentication: :plain,
          enable_starttls_auto: true
        }
      when 'mail'
        ActionMailer::Base.delivery_method = :smtp
        ActionMailer::Base.smtp_settings = {
          address: Dolphin.settings['mail']['host'],
          port: Dolphin.settings['mail']['port'],
        }
    end

    class Mail < ActionMailer::Base
      include Celluloid
      include Dolphin::Util

      def notify(notification_object)
        logger :debug, "Get #{notification_object}"
        send_params = {
          from: notification_object.from,
          to: notification_object.to,
          subject: notification_object.subject,
          body: notification_object.body
        }

        logger :info, send_params
        begin
          mail(send_params).deliver
          logger :info, "Success Sent message"
        rescue => e
          logger :error, e.message
        end
      end
    end
  end
end