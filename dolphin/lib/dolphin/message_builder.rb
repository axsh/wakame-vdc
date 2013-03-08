# -*- coding: utf-8 -*-
require 'erubis'
require 'extlib/blank'

module Dolphin
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
        erubis = Erubis::Eruby.new(str)
        erubis.result(params)
      end
    end

    class Mail < Base

      def build(template_id, params)

        if template_id.blank?
          message = params['messages']['message']
        else
          body_template = template(template_id)
          return nil if body_template.nil?
          message = build_message(body_template, params['messages'])
        end

        notification = NotificationObject.new
        notification.subject = params["subject"]
        notification.from = Dolphin.settings['mail']['from']
        notification.to = params["to"]
        notification.cc ||= params["cc"]
        notification.bcc ||= params["bcc"]
        notification.body = message
        notification
      end

      private
      def template(template_id)
        file_path = File.join(template_path, template_file(template_id))
        if File.exists? file_path
          File.read(file_path)
        else
          logger :error, "File not found #{file_path}"
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