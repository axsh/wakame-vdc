require 'sequel'

module Dcmgr
  module Models
    class LocationGroup < Sequel::Model
      set_dataset :location_groups
      def initialize(name)
        @name = name
      end
      
      attr_reader :name
      
      def keys
        [:name]
      end

      def self.match?(location_tag_name, search_type, search_name)
        puts "match?"
        p [location_tag_name, search_type, search_name]
        idx = index_by_name(search_type)
        return false unless idx
        splits = location_tag_name.split "."
        if splits and splits[idx] == search_name
          true
        else
          false
        end
      end
      
      def self.index_by_name(search_type)
        Dcmgr::location_groups.index{|name|
          name == search_type
        }
      end
      
      def self.all
        Dcmgr::location_groups.map{|name|
          LocationGroup.new(name)
        }
      end
    end
  end
end
