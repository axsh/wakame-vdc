# -*- coding: utf-8 -*-

module Mussel
  MUSSEL_PATH = File.expand_path("../../../../../client/mussel", __FILE__)
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

      def update(uuid, params)
        http_response = JSON.parse(`#{parse_params(params)} #{MUSSEL} #{class_name} update #{uuid}`)
        Responses.const_get(class_name.camelize).new(http_response)
      end

      def show(uuid)
        http_response = JSON.parse(`#{response_format} #{MUSSEL} #{class_name} show #{uuid}`)
        Responses.const_get(class_name.camelize).new(http_response)
      end

      def index
        http_response = JSON.parse(`#{response_format} #{MUSSEL} #{class_name} index`)
        Responses::Collection.generate(class_name.camelize, http_response.first['results'])
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

    class Collection
      # TODO pagination
      def self.generate(klass, array)
        array.map { |i| Responses.const_get(klass).new(i) }
      end
    end

    class SshKeyPair < Base
    end

    class DcNetwork < Base
    end
  end
end
