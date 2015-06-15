# -*- coding: utf-8 -*-

require "fuguta"

module Dcmgr
  module Configurations
    # Base class for all configuration classes.
    class Features < Fuguta::Configuration
      def features
        @config[:features]
      end

      DSL do
        def features(&blk)
          @config[:features].parse_dsl(&blk)
        end
      end

      private
      def after_initialize
        super
        @config[:features] = FeatureKeys.new(self)
      end

      class FeatureKeys < Fuguta::Configuration
        param :openvnet, default: false
      end
    end
  end
end
