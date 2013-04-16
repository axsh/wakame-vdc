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
          File.read(file_path)
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