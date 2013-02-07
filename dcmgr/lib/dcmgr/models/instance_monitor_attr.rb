# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceMonitorAttr < BaseNew

    many_to_one :instance
    plugin :serialization, :yaml, :recipients

    def validate
      super
      self.recipients.each { |i|
        if i.has_key?(:mail_address)
          unless i[:mail_address] =~ /^[^@]+@[a-z0-9][a-z0-9\.\-]+$/i
            errors.add(:recipients, "contains invalid mail address: #{i[:mail_address]}")
          end
        end
      }
    end

    def after_initialize
      super
      self.recipients ||= []
    end

    private

    def before_validation
      self.enabled ||= false
      super
    end
  end
end

