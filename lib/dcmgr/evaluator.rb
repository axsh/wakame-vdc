
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
        Tag.join(:tag_attributes, :tag_id=>:id).filter(:owner_id=>evaluator.id, :tag_attributes__role=>self.class.id).each{|tag|
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

    class CreateAccount < CreateAction; @id = 3; end
    class DestroyAccount < DestroyAction; @id = 4; end
    class CreateImageStorage < CreateAction; @id = 5; end

    class GetImageStorage < Base
      @id = 6

      private
      def _execute(account, user, image_storage_class)
        ImageStorage[params]
      end
    end

    class DestroyImageStorage < DestroyAction; @id = 7; end

    class CreateImageStorageHost < CreateAction; @id = 8; end
    class DestroyImageStorageHost < DestroyAction; @id = 9; end

    class CreatePhysicalHost < CreateAction; @id = 10; end
    class DestroyPhysicalHost < DestroyAction; @id = 11; end

    class CreateHvController < CreateAction; @id = 12; end
    class DestroyHvController < DestroyAction; @id = 13; end

    class CreateHvAgent < CreateAction; @id = 14; end
    class DestroyHvAgent < DestroyAction; @id = 15; end

    @roles = [RunInstance,
              ShutdownInstance,
              CreateAccount,
              DestroyAccount,
              CreateImageStorage,
              GetImageStorage,
              DestroyImageStorage,
              CreateImageStorageHost,
              DestroyImageStorageHost,
              CreatePhysicalHost,
              DestroyPhysicalHost,
              CreateHvController,
              DestroyHvController,
              CreateHvAgent,
              DestroyHvAgent,
             ]

    def self.get(target, action, params={})
      rolename = if target.class == Class
                 then "%s%s" % [action.to_s.capitalize, target.name]
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
