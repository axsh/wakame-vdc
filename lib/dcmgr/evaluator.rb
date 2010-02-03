
module Dcmgr
  class RoleError < StandardError; end
    
  module RoleExecutor
    class Base
      def initialize(target)
        @target = target
      end

      def self.id; @id; end

      def evaluate(evaluator)
        Tag.filter(:owner_id=>evaluator.id, :role=>self.class.id).each{|tag|
          return true if @target.tags.index{|t| tag.tags.include? t}
          return true if @target.class.tags.index{|t| p [tag, t]; tag.name == t.name}
        }
        raise RoleError, "no role(user: #{evaluator.uuid}, target: #{@target.uuid})"
      end

      def execute(evaluator)
        _execute(evaluator, @target)
        true
      end
    end
    
    class RunInstance < Base
      @id = 1
      
      def _execute(user, instance)
        instance.status = Instance::STATUS_TYPE_ONLINE
        instance.save
        true
      end
    end

    class ShutdownInstance < Base
      @id = 2

      private
      def _execute(user, instance)
        instance.status = Instance::STATUS_TYPE_OFFLINE
        instance.save
        true
      end
    end

    class CreateAccount < Base
      @id = 3

      private
      def _execute(user, account)
        account.save
      end
    end

    class DestroyAccount < Base
      @id = 4

      private
      def _execute(user, account)
        account.destroy
      end
    end

    class CreateImageStorage < Base
      @id = 5

      private
      def _execute(user, image_storage)
        image_storage.save
      end
    end

    class DestroyImageStorage < Base
      @id = 6

      private
      def _execute(user, image_storage)
        image_storage.destroy
      end
    end

    @roles = [RunInstance,
              ShutdownInstance,
              CreateAccount,
              DestroyAccount,
              CreateImageStorage,
              DestroyImageStorage]

    def self.[](target, action)
      rolename = "%s%s" % [action.to_s.capitalize, target.class]
      begin
        roleclass = eval("%s" % rolename)
      rescue NameError
        return nil
      end
      return nil unless @roles.include? roleclass
      roleclass.new(target)
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
