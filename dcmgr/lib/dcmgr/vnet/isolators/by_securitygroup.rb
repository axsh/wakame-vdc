# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Isolators
    
      # Isolates instances based on security groups
      # Access to instances in another security group is blocked
      class BySecurityGroup < Isolator
        def determine_friends(me,others)
          #TODO: make sure that me and others are vnic maps
          others.dup.delete_if { |other|
            # Delete if we are not in the same security group
            me[:security_groups].find {|my_group| other[:security_groups].member?(my_group) }.nil?
          }
        end
      end
    
    end
  end
end
