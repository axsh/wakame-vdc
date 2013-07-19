require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module MetricLibs
  describe TimeSeries do
    it '.push' do
      ts = TimeSeries.new

      expect{ts.push(10, nil)}.to raise_error(ArgumentError)

      ts.push(10)
      v = ts.to_a[0]
      expect(v.value).to eql 10
      expect(v.timestamp).to be_kind_of Time
    end

    it '.find' do
      ts = TimeSeries.new

      ts.push(0, Time.at(1374211175))
      ts.push(2, Time.at(1374211175, 300))
      ts.push(1, Time.at(1374211175, 150))
      ts.push(3, Time.at(1374211176))
      expect(ts.to_a.size).to eql 4

      expect{ts.find(Time.now, nil)}.to raise_error(ArgumentError)
      expect{ts.find(nil, Time.now)}.to raise_error(ArgumentError)
      expect{ts.find(nil, nil)}.to raise_error(ArgumentError)

      res = ts.find(Time.at(1374211175), Time.at(1374211175))
      expect(res.size).to eql 3
      expect(res[0].value).to eql 0
      expect(res[1].value).to eql 1
      expect(res[2].value).to eql 2
    end

    it '.delete_all_since_at' do
      ts = TimeSeries.new
      ts.push(0, Time.at(1374211175))
      ts.push(1, Time.at(1374211176))
      ts.push(2, Time.at(1374211177))

      expect{ts.delete_all_since_at(nil)}.to raise_error(ArgumentError)

      ts.delete_all_since_at(Time.at(1374211177))
      res = ts.to_a
      expect(res.size).to eql 1

      v = res[0]
      expect(v.value).to eql 2
      expect(v.timestamp).to be_kind_of Time
    end
  end
end
