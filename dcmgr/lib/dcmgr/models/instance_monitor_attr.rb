# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceMonitorAttr < BaseNew

    many_to_one :instance
    
    def validate
      if self.enabled
        if (self.mailaddr.nil? || self.mailaddr == "")
          errors.add(:mailaddr, "Need to set mail address to send alert")
        elsif self.mailaddr.split('@').size != 2 # check if it has only one '@' symbol 
          errors.add(:mailaddr, "Invalid mail address: #{self.mailaddr}")
        end
      end
    end

    private
    def before_validation
      self.enabled ||= false
      self.mailaddr ||= ""
      super
    end
  end
end

