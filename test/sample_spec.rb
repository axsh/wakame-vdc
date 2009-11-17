# -*- coding: utf-8 -*-

describe Array, "when initialized with object" do
  before do
    @array = Array.new(3){ Hash.new }
    @array[0][:cat] = "Nuko"
  end

  before(:each) do
    print "each\n"
  end

  it "should not affect others" do
    @array == [{:cat => "Nuko"}, {}, {}]
  end
end

describe Array, "when empty" do
  before do
    @empty_array = []
  end

  before(:each) do
    print "each\n"
  end

  it "should be empty" do
    @empty_array.should be_empty
  end

  it "should size 0" do
    @empty_array.size.should == 0
  end

  after do
    @empty_array = nil
  end
end

