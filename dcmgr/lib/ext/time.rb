# -*- coding: utf-8 -*-
require 'time'

class Time
  def to_json(*args)
    self.utc.iso8601.to_s.to_json(*args)
  end
end
