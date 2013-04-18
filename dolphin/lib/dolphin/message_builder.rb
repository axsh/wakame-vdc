# -*- coding: utf-8 -*-
require 'erubis'
require 'extlib/blank'

module Dolphin

  class TemplateBuilder

    include Dolphin::Helpers::Message::ZabbixHelper

    def build(template_str, params)
      template = Erubis::Eruby.new(template_str)
      params.each {|key, val|
        instance_variable_set("@#{key}", val)
      }
      template.result(binding)
    end
  end

  module MessageBuilder

    EXT = '.erb'.freeze

    class Base

      include Dolphin::Util

      def initialize
      end

      def build
        raise NotImplementedError
      end

      def build_message(str, params)
        template = TemplateBuilder.new
        template.build(str, params)
      end
    end

    class Mail < Base

      MESSAGE_BOUNDARY="----------------------------------------".freeze

      def build(template_id, params)
        message = ''

        if template_id.blank?
          template_id = 'default'
        end

        body_template = template(template_id)
        if body_template.nil?
          return nil
        end

        message = build_message(body_template, params['messages'])
        subject, body = message.split(MESSAGE_BOUNDARY)
        subject.strip! unless subject.nil?
        body.strip! unless body.nil?

        notification = NotificationObject.new
        notification.subject = subject
        notification.from = Dolphin.settings['mail']['from']
        notification.to = params["to"]
        notification.cc ||= params["cc"]
        notification.bcc ||= params["bcc"]
        notification.body = body
        notification
      end

      private
      def template(template_id)
        file_path = File.join(template_path, template_file(template_id))
        if File.exists? file_path
          File.read(file_path, :encoding => Encoding::UTF_8)
        else
          logger :warn, "File not found #{file_path}"
          nil
        end
      end

      def template_file(template_id)
        template_id + EXT
      end

      def template_path
        File.join(Dolphin.templates_path, '/email')
      end
    end
  end
end