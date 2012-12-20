# -*- coding: utf-8 -*-

require 'json'

module Hijiki
  # RequestAttribute.configure do |c|
  #   c.service_type = 'std'
  #   c.account_quota_header do
  #     {'instance.count'=>5.0, 'security_group.count'=>10.0}
  #   end
  # end
  # RequestAttribute.new('a-xxxxxxxx', 'std').build_http_headers
  class RequestAttribute
    def self.configure(&blk)
      @configuration = Configuration.parse(&blk)
    end

    def self.configuration
      @configuration || raise("Configuration is not done for RequestAttibute")
    end

    attr :account_id, :service_type, :login_id

    def initialize(account_id, login_id)
      @account_id = account_id
      @service_type = self.class.configuration.service_type
      @login_id = login_id
    end

    def build_http_headers
      {'X-VDC-Account-UUID' => self.account_id,
        'X-VDC-Account-Quota' => JSON.dump( self.class.configuration.generate_quota_header(self)),
        'X-VDC-Requester-Token' => self.login_id
      }
    end

    class Configuration
      def self.parse(&blk)
        self.new(DSL.new.tap{ |i| i.instance_eval(&blk) }.conf)
      end

      def initialize(hash)
        @config = hash
      end

      def service_type
        @config[:service_type]
      end

      def generate_quota_header(request_attribute)
        @config[:quota_header].call(request_attribute)
      end

      class DSL
        attr_reader :conf

        def initialize
          @conf = {}
        end

        def service_type(v)
          @conf[:service_type] = v
        end
        alias :service_type= :service_type

        def quota_header(&blk)
          @conf[:quota_header]=blk
        end
      end
    end
  end
end
