
$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_master.rb'

Wakame.config.status_db_dsn = 'sqlite:///'

Wakame::Initializer.run(:setup_database)

class TestStatusDB < Test::Unit::TestCase

  class Model1 < Wakame::StatusDB::Model
    property :a
    property :b
    property :c
    property :d

    property :e, {:default=>"set in Model1"}
    property :f, {:default=>"f"}
  end

  class Model2 < Model1
    property :n
    property :e, {:default=>"set in Model2"}
    def_attribute :f, {:persistent=>false}
  end

  def test_model1
    m1 = Model1.new
    m1.a = "a"
    m1.b = 12.33
    m1.c = nil
    time_d = m1.d = Time.new

    pk = m1.id

    assert_equal(true, m1.dirty?)
    m1.save

    assert_equal(true, Model1.exists?(pk))
    assert_equal(false, Model1.exists?(pk+"hoge"))

    m1 = Model1.find(pk)
    assert_equal(pk, m1.id)
    assert_equal("a", m1.a)
    assert_equal(12.33, m1.b)
    assert_equal(nil, m1.c)
    assert_equal(time_d.to_s, m1.d)
    assert_equal(false, m1.dirty?)

    m1.a = "b"
    assert_equal("b", m1.a)
    assert_equal(true, m1.dirty?)
    assert_equal(true, m1.dirty?(:a))

    m1.save
    assert_equal(false, m1.dirty?)
    assert_equal(false, m1.dirty?(:a))
    assert_equal("b", m1.a)

  end

  def test_model2
    m = Model2.new
    pk = m.id
    m.a = "a"
    m.n = "n"

    assert_equal(nil, m.f)

    m.save

    m = Model1.find(pk)
    assert_equal(Model2, m.class)
    assert_equal("a", m.a)
    assert_equal(nil, m.b)
    assert_equal(nil, m.f)
    assert_equal("n", m.n)
    assert_equal("set in Model2", m.e)

  end

end
