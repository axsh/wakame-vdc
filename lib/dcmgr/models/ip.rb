module Dcmgr
  module Models
    class Ip < Sequel::Model
      many_to_one :ip_group
    end
  end
end
