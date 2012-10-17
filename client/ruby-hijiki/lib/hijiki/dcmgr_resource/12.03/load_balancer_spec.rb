#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'

module Hijiki::DcmgrResource::V1203
  class LoadBalancerSpec < Base
    module ClassMethods
      def load_spec(path)
        # TODO: move to common function
        @load_balancer_specs = YAML.load_file(path) || {}
        @load_balancer_specs = Hash[*@load_balancer_specs.map{|k,v| [k, ActiveSupport::HashWithIndifferentAccess.new(v)] }.flatten].freeze
        # validation
        errors = false
        @load_balancer_specs.each { |k, v|
          # check if all required parameters exist.
          a = [:max_connection, :engine] - v.keys.map(&:to_sym)
          unless a.empty?
            STDERR.puts "ERROR: missing required load_balancer spec parameters in '#{k}': #{a.join(', ')}"
            errors = true
          end

          v['id'] = k
          v['uuid'] = k
          v.freeze
        }
        raise "There are one or more errors in #{path}" if errors
        @load_balancer_specs
      end

      def show(key)
        new(@load_balancer_specs[key])
      end
    end

    extend ClassMethods
  end
end
