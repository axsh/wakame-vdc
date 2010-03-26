require 'sequel'

module Dcmgr
  module Models
    class Ip < Sequel::Model
      many_to_one :ip_group
      many_to_one :instance

      # dataset filtered by group_name
      def self.find_by_group_name(group_name)
        filter(:ip_group_id=>IpGroup.find(:name=>group_name).id)
      end

      def to_s
        self.ip
      end
    end
  end
end
