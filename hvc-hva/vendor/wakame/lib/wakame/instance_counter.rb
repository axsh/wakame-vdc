module Wakame
  class InstanceCounter
    class OutOfLimitRangeError < StandardError; end
    
    include AttributeHelper
    
    def bind_resource(resource)
      @resource = resource
    end
    
    def resource
      @resource
    end
    
    def instance_count
      raise NotImplementedError
    end
    
    protected
    def check_hard_limit(count=self.instance_count)
      Range.new(@resource.min_instances, @resource.max_instances, true).include?(count)
    end
  end
  
  
  class ConstantCounter < InstanceCounter
    def initialize(resource)
      @instance_count = 1
      bind_resource(resource)
    end
    
    def instance_count
      @instance_count
    end
    
    def instance_count=(count)
      raise OutOfLimitRangeError unless check_hard_limit(count)
      if @instance_count != count
        prev = @instance_count
        @instance_count = count
        ED.fire_event(Event::InstanceCountChanged.new(@resource, prev, count))
      end
    end
  end
  
  class TimedCounter < InstanceCounter
    def initialize(seq, resource)
      @sequence = seq
      bind_resource(resource)
      @timer = Scheduler::SequenceTimer.new(seq)
      @timer.add_observer(self)
      @instance_count = 1
    end
    
    def instance_count
      @instance_count
    end
    
    def update(*args)
      new_count = args[0]
      if @instance_count != count
        prev = @instance_count
        @instance_count = count
        ED.fire_event(Event::InstanceCountChanged.new(@resource, prev, count))
      end
      #if self.min > new_count || self.max < new_count
      #if self.min != new_count || self.max != new_count
      #  prev_min = self.min
      #  prev_max = self.max
      
      #  self.max = self.min = new_count
      #  ED.fire_event(Event::InstanceCountChanged.new(@resource, prev_min, prev_max, self.min, self.max))
      #end
      
    end
  end

end
