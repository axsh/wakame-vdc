# -*- coding: utf-8 -*-

module MetricLibs

  module TimerError
    class TimerCancelError < Exception; end
    class TimerNotFoundError < Exception; end
  end
  
  class Timer
    include TimerError
    
    def cancel
      raise TimerCancelError
    end

    def add_periodic_timer(alm)
      raise TimerNotFoundError
    end

  end
end
