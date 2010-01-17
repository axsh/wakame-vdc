
module Dcmgr
  class RoleError < StandardError; end
    
  module RoleExecutor
    class Base
    end
    
    class ShutdownInstance < Base
      def initialize(instance)
        @instance = instance
      end
      
      def self.id; 1; end
      
      def evaluate(evaluator)
        Tag.filter(:owner_id=>evaluator.id, :role=>ShutdownInstance.id).each{|tag|
          @instance.tags.each{|t|
            return if tag.tags.include? t
          }
        }
        raise RoleError.new("no role(user: %s, target: %s)" % [evaluator.uuid, @instance.uuid])
      end

      def execute(user)
        @instance.status = Instance::STATUS_TYPE_OFFLINE
        @instance.save
        true
      end
    end

    @roles = [ShutdownInstance]

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
