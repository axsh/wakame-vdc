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
        JSON.parse(`#{parse_params(params)} #{MUSSEL} #{class_name} create`)
      end

      def destroy(params)
        JSON.parse(`#{parse_params(params)} #{MUSSEL} #{class_name} destroy`)
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
end
