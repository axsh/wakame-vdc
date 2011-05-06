class Time
  def to_json(*args)
    self.utc.iso8601
  end
end
