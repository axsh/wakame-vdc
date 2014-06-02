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

    def after_save
      super

      if self.instance
        # insert/update same values as resource labels
        self.instance.set_label('monitoring.enabled', self.enabled.to_s)
        (0..9).each { |idx|
          if recipients[idx] && recipients[idx][:mail_address]
            self.instance.set_label("monitoring.mail_address.#{idx}", recipients[idx][:mail_address])
          elsif self.instance.label("monitoring.mail_address.#{idx}")
            self.instance.unset_label("monitoring.mail_address.#{idx}")
          end
        }
      end
    end
  end
end

