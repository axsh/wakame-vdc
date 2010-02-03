
module Dcmgr
  class RoleError < StandardError; end
    
  module RoleExecutor
    class Base
      def initialize(target, params)
        @target = target
        @params = params
      end

      def self.id; @id; end

      def class_type?
        @target.class == Class
      end

      def evaluate(account, evaluator)
        Tag.filter(:owner_id=>evaluator.id, :role=>self.class.id).each{|tag|
          if class_type?
            return true

          else
            return true if @target.tags.index{|t| tag.tags.include? t}
            return true if @target.class.tags.index{|t| tag.name == t.name}
          end
        }
        raise RoleError, "no role" +
          "(user: #{evaluator.uuid}, target: #{@target})"
      end

      def execute(account, evaluator)
        _execute(account, evaluator, @target)
      end

      attr_reader :params
    end
    
    class RunInstance < Base
      @id = 1
      
      def _execute(account, user, instance)
        instance.status = Instance::STATUS_TYPE_ONLINE
        instance.save
        true
      end
    end

    class ShutdownInstance < Base
      @id = 2

      private
      def _execute(account, user, instance)
        instance.status = Instance::STATUS_TYPE_OFFLINE
        instance.save
        true
      end
    end

    class CreateAccount < Base
      @id = 3

      private
      def _execute(account, user, target_account)
        target_account.save
        true
      end
    end

    class DestroyAccount < Base
      @id = 4

      private
      def _execute(account, user, target_account)
        target_account.destroy
        true
      end
    end

    class CreateImageStorage < Base
      @id = 5

      private
      def _execute(account, user, image_storage)
        image_storage.save
        true
      end
    end

    class GetImageStorageClass < Base
      @id = 6

      private
      def _execute(account, user, image_storage_class)
        ImageStorage[params]
      end
    end

    class DestroyImageStorage < Base
      @id = 7

      private
      def _execute(account, user, image_storage)
        image_storage.destroy
        true
      end
    end

    class CreateAction < Base
      def _execute(accont, user, target)
        target.save
        true
      end
    end

    class DestroyAction < Base
      def _execute(accont, user, target)
        target.destroy
        true
      end
    end

    class CreateImageStorageHost < CreateAction; @id = 8; end
    class DestroyImageStorageHost < DestroyAction; @id = 9; end

    @roles = [RunInstance,
              ShutdownInstance,
              CreateAccount,
              DestroyAccount,
              CreateImageStorage,
              GetImageStorageClass,
              DestroyImageStorage,
              CreateImageStorageHost,
              DestroyImageStorageHost,
             ]

    def self.get(target, action, params={})
      rolename = if target.class == Class
                 then "%s%sClass" % [action.to_s.capitalize, target.name]
                 else"%s%s" % [action.to_s.capitalize, target.class]
                 end
      begin
        roleclass = eval("%s" % rolename)
      rescue NameError
        return nil
      end
      return nil unless @roles.include? roleclass
      roleclass.new(target, params)
    end

    def self.roles
      @roles
    end
  end

  # auth target is image or user
  def self.evaluate(evaluator, target, action)
    raise ArgumentError.new("unknown class: %s" % evaluator) unless evaluator.is_a?(User)
    
    role = RoleExecutor[target, action]
    raise ArgumentError.new("unkown role(target: %s, action: %s)" % [target, action]) unless role
    
    Dcmgr::logger.debug("role: %s" % role)
    role.evaluate(evaluator)
    
    role.execute(evaluator)
  end
end
