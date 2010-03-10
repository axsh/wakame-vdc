require 'sequel'

module Dcmgr
  module Models
    class Ip < Sequel::Model
      many_to_one :ip_group
      many_to_one :instance

      def to_s
        self.ip
      end
    end
  end
end
