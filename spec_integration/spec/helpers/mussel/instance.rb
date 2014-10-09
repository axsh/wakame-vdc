# -*- coding: utf-8 -*-

module Mussel
  class Instance < Base

    class << self
      def create(params)
        super(params)
      end

      def destroy(instance)
        super(instance.id)
      end

      def power_off(instance, force = true)
        http_response = JSON.parse(`#{parse_params({:force => force})} #{MUSSEL} instance poweroff #{instance.id}`)
        Responses.const_get(class_name.camelize).new(http_response)
      end

      def power_on(instance)
        http_response = JSON.parse(`#{response_format} #{MUSSEL} instance poweron #{instance.id}`)
        Responses.const_get(class_name.camelize).new(http_response)
      end
    end
  end

  module Responses
    class Instance < Base
    end
  end
end
