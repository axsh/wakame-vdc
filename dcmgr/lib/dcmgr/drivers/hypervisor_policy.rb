# encoding: utf-8

module Dcmgr
  module Drivers
    # check/validate API request/Model parameters specifically for selected hypervisor.
    class HypervisorPolicy
      ValidationError = Class.new(StandardError)

      def validate_instance_model(instance)
      end

      def validate_volume_model(volume)
      end

      def on_associate_volume(instance, volume)
      end
    end
  end
end
