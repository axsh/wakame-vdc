module Dcmgr
  module Models
    class LocationGroup < Sequel::Model
      def initialize(name)
        @name = name
      end
      
      attr_reader :name
      
      def keys
        [:name]
      end
      
      def self.all
        Dcmgr::location_groups.map{|name|
          LocationGroup.new(name)
        }
      end
    end
  end
end
