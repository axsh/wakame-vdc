# -*- coding: utf-8 -*-

require 'celluloid'

module Dolphin
  module Util
    include Celluloid::Logger

    def logger(type, message)
      message = {
        :message => message,
        :classname => self.class.name,
        :thread_id => Thread.current.object_id
      }
      Celluloid.logger.__send__(type, message)
    end
  end
end