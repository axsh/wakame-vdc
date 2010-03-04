module Dcmgr
  module Models
    class KeyPair < Sequel::Model
      include Base
      def self.prefix_uuid; 'KP'; end
      
      many_to_one :user
      
      def before_create
        super
        keypair = Dcmgr::KeyPairFactory.generate(self.uuid)
        self.public_key = keypair[:public]
        self.private_key = keypair[:private]
      end
      
      attr_accessor :private_key
    end
  end
end
