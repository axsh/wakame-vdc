# -*- coding: utf-8 -*-

module MetricLibs
  class AlarmManager

    def initialize(timer=nil)
      @timer = timer
      # @manager = {:alarm_id => {:timer => @timer, :alarm => Alarm.new}
      @manager = {}
    end

    def update(alm)
      if alm[:enabled]
        if get_hash(alm[:uuid])
          if @timer.nil?
            update_alarm(alm)
          else
            cancel_update_alarm(alm)
          end
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

    def update_resource(uuid, resource)
      raise ArgumentError unless uuid.is_a?(String)
      raise ArgumentError unless resource.is_a?(Hash)
      get_alarm(uuid).feed(resource)
    end

    def evaluate(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      get_alarm(uuid).evaluate
    end

    def find_alarm(resource_id, resource)
      raise ArgumentError unless resource.is_a?(Hash)

      alarm = @manager.values.keep_if {|alm|
        alm[:alarm].resource_id == resource_id &&
        resource[alm[:alarm].metric_name]
      }
      return nil if alarm.empty?
      alarm.first[:alarm]
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

    def update_alarm(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      get_alarm(alm[:uuid]).update(alm)
    end

    def cancel_update_alarm(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      get_timer(alm[:uuid]).cancel
      update_alarm(alm)
      set_timer(alm[:uuid])
    end

    def create_alarm(alm)
      raise ArgumentError unless alm.is_a?(Hash)
      set_hash(alm[:uuid])
      set_alarm(alm)
      set_timer(alm[:uuid]) unless @timer.nil?
    end

    def delete_alarm(uuid)
      raise ArgumentError unless uuid.is_a?(String)
      if get_hash(uuid)
        get_timer(uuid).cancel unless @timer.nil?
        delete_hash(uuid)
      end
    end

  end
end

