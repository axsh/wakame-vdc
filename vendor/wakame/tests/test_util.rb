
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'

require 'test/unit'
require 'wakame/util'

WAKAME_ROOT="#{File.dirname(__FILE__)}/.."

class TestUtilClass < Test::Unit::TestCase
  class A
    include AttributeHelper
    
    def_attribute :a, 1
    def_attribute :b, {:default=>2, :persistent=>true}
    def_attribute :c, []
    attr :m
    attr_accessor :n, :o
    attr_reader :p
  end


  class B < A
    def_attribute :d, 30
    def_attribute :e, 'aaa'
    def_attribute :f
  end

  class C < B
    update_attribute :b, {:a=>1, :b=>1}
    update_attribute :d, {:a=>1, :b=>1}
  end

  def test_attribute_helper1
    a = A.new
    assert_equal(1, a.a)
    assert_equal(2, a.b)
    assert_equal([], a.c)
    assert_equal({:type=>'TestUtilClass::A', :a=>1, :b=>2, :c=>[], :m=>nil, :n=>nil, :o=>nil, :p=>nil}, a.dump_attrs)

    b = B.new
    assert(b.kind_of?(AttributeHelper))
    assert_equal(1, b.a)
    assert_equal(2, b.b)
    assert_equal([], b.c)
    assert_equal(30, b.d)
    assert_equal('aaa', b.e)
    assert(b.f == nil)
    assert_equal( {:type=>'TestUtilClass::B', :a=>1, :b=>2, :c=>[], :d=>30, :e=>'aaa', :f=>nil, :m=>nil, :n=>nil, :o=>nil, :p=>nil}, b.dump_attrs)
  end


  def test_attribute_helper2
    c = C.new
    assert_equal({:default=>{:a=>1, :b=>1}, :persistent=>true}, C.get_attr_attribute(:b))
    assert_equal({:default=>{:a=>1, :b=>1}}, C.get_attr_attribute(:d))
  end


  H={23=>1, 38=>3, 2837=>1, 3727=>4, 937=>1, 184=>5, 328=>2, 8939=>1}
  def test_sorted_hash1
    s = SortedHash.new
    
    H.keys.sort_by{rand}.each { |k|
      s[k]=H[k]
    }
    
    assert_equal(H.keys.sort, s.keys)
    
    s.clear
    assert_equal([], s.keys)

  end


  def test_snake_case
    {'CNN'=>'cnn', 'CNNNews'=>'cnn_news', 'NewsCNN'=>'news_cnn', 'Apache_WWW'=>'apache_www', 'ApacheAPP'=>'apache_app', 'HeadlineCNNNews'=>'headline_cnn_news'}.each { |k,v|
      assert_equal(v, Wakame::Util.snake_case(k))
    }
  end

end
