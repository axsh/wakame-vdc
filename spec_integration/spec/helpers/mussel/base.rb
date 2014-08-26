# -*- coding: utf-8 -*-

module Mussel
  MUSSEL_PATH='/opt/axsh/wakame-vdc/client/mussel'
  MUSSEL = "#{MUSSEL_PATH}/mussel.sh"
  RESPONSE_FORMAT='json'

  class Base
    class << self
      def class_name
        self.name.split("::").last.underscore
      end

      def create(params)
        http_response = JSON.parse(`#{parse_params(params)} #{MUSSEL} #{class_name} create`)
        Responses.const_get(class_name.camelize).new(http_response)
      end

      def destroy(uuid)
        JSON.parse(`#{response_format} #{MUSSEL} #{class_name} destroy #{uuid}`)
      end

      def show(uuid)
        http_response = JSON.parse(`#{response_format} #{MUSSEL} #{class_name} show #{uuid}`)
        Responses.const_get(class_name.camelize).new(http_response)
      end

      def parse_params(params)
        str = response_format
        params.keys.each do |k|
          str = "#{str} #{k}=#{params[k]}"
        end
        str
      end

      def response_format
        "DCMGR_RESPONSE_FORMAT=#{RESPONSE_FORMAT}"
      end
    end
  end

  class SshKeyPair < Base
  end

  class DcNetwork < Base
  end

  module Responses
    class Base < OpenStruct
    end

    class SshKeyPair < Base
    end

    class DcNetwork < Base
    end
  end
end
