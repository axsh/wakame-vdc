# -*- coding: utf-8 -*-

require 'celluloid'
require 'action_mailer'
require 'mail-iso-2022-jp'
require 'extlib/blank'

module Dolphin

  module Sender
    TYPES = ['email'].freeze

    TYPE = [:mail_senders].freeze

    ActionMailer::Base.raise_delivery_errors = true
    case Dolphin.settings['mail']['type']
      when 'file'
        ActionMailer::Base.delivery_method = :file
        ActionMailer::Base.file_settings = {
          :location => '/var/tmp'
        }
      when 'tls-mail'
        ActionMailer::Base.delivery_method = :smtp
        ActionMailer::Base.smtp_settings = {
          :address => Dolphin.settings['mail']['host'],
          :port => Dolphin.settings['mail']['port'],
          :user_name => Dolphin.settings['mail']['user_name'],
          :password => Dolphin.settings['mail']['password'],
          :authentication => :plain,
          :enable_starttls_auto => true
        }
      when 'mail'
        ActionMailer::Base.delivery_method = :smtp
        ActionMailer::Base.smtp_settings = {
          :address => Dolphin.settings['mail']['host'],
          :port => Dolphin.settings['mail']['port'],
        }
    end

    class Mail < ActionMailer::Base
      include Celluloid
      include Dolphin::Util

      default :charset => 'ISO-2022-JP'

      def notify(notification_object)
        send_params = {
          :from => notification_object.from,
          :to => notification_object.to,
          :subject => notification_object.subject,
          :body => notification_object.body
        }

        unless notification_object.to.blank?
          send_params[:cc] = notification_object.cc
        end

        unless notification_object.bcc.blank?
          send_params[:bcc] = notification_object.bcc
        end

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