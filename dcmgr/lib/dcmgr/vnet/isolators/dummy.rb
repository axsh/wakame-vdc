# -*- coding: utf-8 -*-

module Dcmgr
  module Vnet
    module Isolators
    
      # This isolator just returns an empty array as friends
      # This means all instances will be isolated from each other
      class DummyIsolator < Isolator
        def determine_friends(me,others)
          []
        end
      end
    
    end
  end
end
