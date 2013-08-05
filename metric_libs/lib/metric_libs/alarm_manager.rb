# -*- coding: utf-8 -*-

module MetricLibs
  class AlarmManager

    def initialize(timer)
      @timer = timer
      # @manager = {:alarm_id => {:timer => @timer, :alarm => Alarm.new}
      @manager = {}
    end

    def update(alm)
      if alm[:enabled]
        if get_hash(alm[:uuid])
          cancel_update_alarm(alm)
        else
          create_alarm(alm)
        end
      else
        delete_alarm(alm[:uuid])
      end
    end

    def updates(alms)
      raise ArgumentError unless alms.is_a?(Array)
      alms.each {|alm|
        update(alm)
      }
    end

    def delete(alm)
      delete_alarm(alm[:uuid])
    end

    def deletes(alms)
      raise ArgumentError unless alms.is_a?(Array)
      alms.each {|alm|
        delete(alm)
      }
    end

    def update_resources(resources)
      raise ArgumentError unless resources.is_a?(Hash)
      @manager.each_value {|alm|
        alm[:alarm].feed(resources)
      }
    end

    private
    def get_hash(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      @manager[uuid]
    end

    def get_alarm(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      @manager[uuid][:alarm]
    end

    def get_timer(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      @manager[uuid][:timer]
    end

    def set_hash(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      @manager[uuid] ||= {}
    end

    def set_alarm(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      @manager[alm[:uuid]][:alarm] = Alarm.new(alm, self)
    end

    def set_timer(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      @manager[uuid][:timer] = @timer.add_periodic_timer(get_alarm(uuid))
    end

    def delete_hash(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      @manager.delete(uuid)
    end

    def cancel_update_alarm(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      get_timer(alm[:uuid]).cancel
      get_alarm(alm[:uuid]).update(alm)
      set_timer(alm[:uuid])
    end

    def create_alarm(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      set_hash(alm[:uuid])
      set_alarm(alm)
      set_timer(alm[:uuid])
    end

    def delete_alarm(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      if get_hash(uuid)
        get_timer(uuid).cancel
        delete_hash(uuid)
      end
    end

  end
end

