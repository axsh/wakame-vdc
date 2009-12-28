
module Dcmgr
  class RollException < Exception; end
    
  module Roll
    class Base
    end
    
    class InstanceShutdown < Base
      def initialize(instance)
        @instance = instance
      end
      
      def self.id; 1; end
      
      def enable?(evalutor)
        evalutor.tags.each{|tag|
          if tag.tags.include? instance.tag
            return true
          end
        }
        false
      end

      def evalute(user)
        @instance.status = Instance::STATUS_TYPE_STOP
        @instance.save
        true
      end
    end

    @rolls = [InstanceShutdown]

    def self.roll(target, action)
      rollname = "%s%s" % [target.class, action.to_s.capitalize]
      begin
        rollclass = eval("%s" % rollname)
      rescue NameError
        return nil
      end
      return nil unless @rolls.include? rollclass
      return rollclass.new(target)
    end
  end

  # auth target is image or user
  def self.evalute(evalutor, target, action)
    if evalutor.is_a?(User)
      roll = Roll.roll(target, action)
      raise ArgumentError.new("unkown roll(target: %s, action: %s)" % [target, action]) unless roll
      Dcmgr::logger.debug("roll: %s" % roll)
      if roll.enable?(evalutor)
        return roll.evalute(evalutor)
      else
        raise RollException.new("can't %s(evalutor: %s, target: %s" % [action, target])
      end
    end
    raise ArgumentError.new("unknown class: %s" % evalutor)
  end
end
