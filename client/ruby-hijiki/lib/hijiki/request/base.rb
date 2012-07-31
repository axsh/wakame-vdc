# -*- coding: utf-8 -*-
require 'weary'

module Hijiki::Request::Common

  class Defaults
    def self.request_defaults
      @@request_defaults ||= {
        :format => 'json',
        :service_type => 'std',
      }
    end
  end

  module Helpers
    module ClassMethods
      def namespace(name, version)
        self.domain("{+domain}/api/#{version}/#{name}")
      end
    end

    def self.included(klass)
      klass.extend ClassMethods
      klass.defaults Defaults.request_defaults
    end
  end

end
