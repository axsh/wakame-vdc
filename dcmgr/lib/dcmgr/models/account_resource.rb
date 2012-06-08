# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Base class for the model class which belongs to a specific account.
  class AccountResource < BaseNew

    # Selectively enable service type namespace.
    #
    # Most of child classes of this class are having service type
    # field. but a few of them are not so this method is called if the class is service type
    def self.accept_service_type
      self.plugin(EnableServiceType)
    end

    # Sequel plugin for setting up hooks needed for service type support.
    module EnableServiceType
      module InstanceMethods
        def before_validation
          self.service_type ||= Dcmgr.conf.default_service_type
          super
        end

        def validate
          unless Dcmgr.conf.service_types[self.service_type.to_s]
            errors.add(:service_type, "Unknown service type: #{self.service_type}")
          end
          super
        end
      end
      
    end
    
    def account
      Account[self.account_id]
    end

  end
end
