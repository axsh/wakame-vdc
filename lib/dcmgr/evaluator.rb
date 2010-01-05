
module Dcmgr
  class RollException < Exception; end
    
  module RollExecutor
    class Base
    end
    
    class ShutdownInstance < Base
      def initialize(instance)
        @instance = instance
      end
      
      def self.id; 1; end
      
      def evaluate(evalutor)
        evalutor.tags.each{|tag|
          if tag.tags.include? instance.tag
            return
          end
        }
        raise RollException(user, self)
      end

      def execute(user)
        @instance.status = Instance::STATUS_TYPE_STOP
        @instance.save
        true
      end
    end

    @rolls = [ShutdownInstance]

    def self.[](target, action)
      rollname = "%s%s" % [action.to_s.capitalize, target.class]
      begin
        rollclass = eval("%s" % rollname)
      rescue NameError
        return nil
      end
      return nil unless @rolls.include? rollclass
      rollclass.new(target)
    end
  end

  # auth target is image or user
  def self.evaluate(evalutor, target, action)
    raise ArgumentError.new("unknown class: %s" % evalutor) unless evalutor.is_a?(User)
    
    roll = RollExecutor[target, action]
    raise ArgumentError.new("unkown roll(target: %s, action: %s)" % [target, action]) unless roll
    Dcmgr::logger.debug("roll: %s" % roll)
    raise RollException.new("can't %s(evalutor: %s, target: %s" % [action, target]) unless roll.evaluate(evalutor)
    roll.execute(evalutor)
  end
end
