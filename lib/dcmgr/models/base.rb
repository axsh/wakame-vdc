require 'sequel'

module Dcmgr
  module Models
    class InvalidUUIDError < StandardError; end
    class DuplicateUUIDError < StandardError; end

    module UUIDMethods
      module ClassMethods
        # override [] method. add search by uuid String
        def [](*args)
          if args.size == 1 and args[0].is_a? String
            super(:uuid=>trim_uuid(args[0]))
          else
            super(*args)
          end
        end
        
        def trim_uuid(p_uuid)
          if p_uuid and p_uuid.length == self.prefix_uuid.length + 9
            return p_uuid[(self.prefix_uuid.length+1), p_uuid.length]
          end
          raise InvalidUUIDError, "invalid uuid: #{p_uuid}"
        end

        #def tags
        #  [Tag.new(:name=>"%s-_ROLETAG" % [self.prefix_uuid])]
        #end
      end
      
      def generate_uuid
        "%08x" % rand(16 ** 8)
      end

      def setup_uuid
        self.uuid = generate_uuid unless self.values[:uuid]
      end

      def before_create
        setup_uuid
      end

      def save(*columns)
        super
      rescue Sequel::DatabaseError => e
        raise DuplicateUUIDError if /^Mysql::Error: Duplicate/ =~ e.message
        raise e
      end

      def uuid
        "%s-%s" % [self.class.prefix_uuid, self.values[:uuid]]
      end

      def to_s
        uuid
      end
    end

    class Base < Sequel::Model
      include UUIDMethods

      def self.included(mod)
        mod.extend UUIDMethods::ClassMethods
      end
    end
  end
end
