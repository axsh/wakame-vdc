# -*- coding: utf-8 -*-

module Dolphin
  module MessageBuilder
    class Base
      def initialize
      end

      def build
        raise NotImplementedError
      end
    end

    class Mail < Base
      def build(template_id, params)
        #TODO: Merge template file using template_id
        message = NotificationObject.new
        message.subject = params["subject"]
        message.from = Dolphin.settings['mail']['from']
        message.to = params["to"]
        message.cc ||= params["cc"]
        message.bcc ||= params["bcc"]
        message.body = params["message"]
        message
      end
    end
  end
end