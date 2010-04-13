module Dcmgr
  module Models
    class IpGroup < Base
      set_dataset :ip_groups
      set_prefix_uuid 'IG'

      one_to_many :ips

      def before_create
        super
      end

      def validate
        errors.add(:name, "can't empty") unless self.name
      end
    end
  end
end
