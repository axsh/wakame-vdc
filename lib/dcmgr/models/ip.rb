require 'sequel'

module Dcmgr
  module Models
    class Ip < Sequel::Model
      many_to_one :ip_group
      many_to_one :instance
    end
  end
end
