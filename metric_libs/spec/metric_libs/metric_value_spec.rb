require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module MetricLibs
  describe MetricValue do
    it '.new' do
      now = Time.now
      mv = MetricValue.new(1, now)
      expect(mv.value).to eql 1
      expect(mv.timestamp).to be_kind_of Time
      expect(mv.timestamp).to eql now

      expect{MetricValue.new(1, nil)}.to raise_error(ArgumentError)
    end
  end
end
