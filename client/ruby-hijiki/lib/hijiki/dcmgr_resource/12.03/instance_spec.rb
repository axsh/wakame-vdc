# -*- coding: utf-8 -*-

require 'yaml'

module Hijiki::DcmgrResource::V1203
  class InstanceSpec < Base
    module ClassMethods
      def load_spec(path)
        @instance_specs = YAML.load_file(path)
        @instance_specs = Hash[*@instance_specs.map{|k,v| [k, ActiveSupport::HashWithIndifferentAccess.new(v)] }.flatten].freeze
        # validation
        errors = false
        @instance_specs.each { |k, v|
          # check if all required parameters exist.
          a = [:cpu_cores, :memory_size, :hypervisor, :quota_weight] - v.keys.map(&:to_sym)
          unless a.empty?
            STDERR.puts "ERROR: missing required instance spec parameters in '#{k}': #{a.join(', ')}"
            errors = true
          end

          v['id'] = k
          v['uuid'] = k
          v.freeze
        }
        raise "There are one or more errors in #{path}" if errors
        @instance_specs
      end

      def list(params = {})
        instantiate_collection([{:total=> @instance_specs.size, :results=>@instance_specs.values}])
      end

      def show(key)
        new(@instance_specs[key])
      end
    end

    extend ClassMethods
  end
end
