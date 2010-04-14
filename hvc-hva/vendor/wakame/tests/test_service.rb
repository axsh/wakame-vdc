

$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_master.rb'

require 'eventmachine'
require 'wakame/service.rb'
require 'wakame/event_dispatcher.rb'

# Store to sqlite memory database
Wakame.config.status_db_dsn = 'sqlite:///'

class TestService < Test::Unit::TestCase
  include Wakame::Service

  module ResType1; end
  module ResType2; end
  module ResType3; end

  class Res1 < Resource
    include ResType1
  end

  class Res2 < Resource
    include ResType2
  end

  class Res3 < Resource
    include ResType3
  end

  class Res4 < Resource
  end

  def create_dummy_cluster
    c = ServiceCluster.new
    c.name= 'TestCluster1'
    c.add_resource(Res1.new)
    c.add_resource(Res2.new)
    c.add_resource(Res3.new)
    c.add_resource(Res4.new)

    c.set_dependency(Res2, Res1)
    c.set_dependency(Res3, Res1)
    c.set_dependency(Res4, Res3)

    c.save
    c
  end

  def teardown
    #Wakame::StatusDB.adapter.clear_store
  end

  def test_resource
    assert_equal(Res1.id, Resource.id(Res1))
    res1 = Res1.new
    assert_equal(res1.id, Resource.id(Res1))
    assert_not_equal(Res2.id, Resource.id(Res3))
    assert_equal(Res4.id, Resource.id(Res4))
  end

  def test_create_cluster
    c = create_dummy_cluster
  end

  def hash_sort_ary(ary)
    ary.collect{|i| i.id.hash }.sort
  end

  def test_dg
    c = create_dummy_cluster
    
    assert_equal([hash_sort_ary([Res4, Res2]), hash_sort_ary([Res3]), hash_sort_ary([Res1])], 
                 c.dg.levels.collect{|i| i.collect{|k| k.id.hash}.sort })
    
    assert_equal(hash_sort_ary([Res2, Res3]), hash_sort_ary(c.dg.parents(Res1)))
    assert_equal([], c.dg.children(Res1))
    assert_equal(hash_sort_ary([Res1]), hash_sort_ary(c.dg.children(Res2)))
    assert_equal([], c.dg.parents(Res2))
    assert_equal(hash_sort_ary([Res1]), hash_sort_ary(c.dg.children(Res3)))
    assert_equal(hash_sort_ary([Res4]), hash_sort_ary(c.dg.parents(Res3)))
    assert_equal(hash_sort_ary([Res3]), hash_sort_ary(c.dg.children(Res4)))
    assert_equal([], c.dg.parents(Res4))
  end


  def test_cluster_methods
    c = create_dummy_cluster
    res2 = Resource.find(Res2.id)
    res2.max_instances = 3
    res2.save

    h = c.add_host

    c.propagate(Res1, h.id)
    c.propagate(Res2, h.id)
    c.propagate(Res3, h.id)
    c.propagate(Res4, h.id)

    assert_equal(4, c.services.size)
    assert_equal(1, c.hosts.size)
    [Res1, Res2, Res3, Res4].each {|r|
      assert( c.resources.member?(r.id) )
    }

    assert_raise(RuntimeError) {
      c.propagate(Res2)
    }
    assert_raise(RuntimeError) {
      c.propagate(Res2, h.id)
    }

    h2 = c.add_host { |h|
      h.vm_spec.attr1 = "attr1"
      h.vm_spec.attr2 = "attr2"
      h.vm_spec.attr3 = "attr3"
    }

    res2_svc2 = c.propagate(Res2, h2.id)
    assert_equal(2, c.hosts.size)
    assert_equal(5, c.services.size)

    res2_svc3 = c.propagate_service(res2_svc2.id)
    assert_equal(3, c.hosts.size)
    assert_equal(6, c.services.size)
    assert_equal({:attr1=>"attr1", :attr2=>"attr2", :attr3=>"attr3"}, res2_svc3.host.vm_attr)
    
  end


  def test_each_instance
    c = create_dummy_cluster
    c.launch

    {ResType1=>Res1, ResType2=>Res2, ResType3=>Res3}.each { |k,v|
      c.each_instance(k) { |svc|
        assert(svc.resource.is_a?(v))
      }
    }
  end


  def test_vmspec
    spec = VmSpec.define {
      environment(:EC2) { |ec2|
        ec2.instance_type = 'm1.small'
        ec2.availability_zone = 'us-east-c1'
        ec2.security_groups << 'default'
      }
      
      environment(:StandAlone) {
      }
    }


    Wakame.config.vm_environment = :EC2
    p spec.current.attrs
    Wakame.config.vm_environment = :StandAlone
    p spec.current.attrs

    assert_raise(RuntimeError) {
      Wakame.config.vm_environment = :EC3
      spec.current.attrs
    }
  end


  def test_queued_lock
    q = Wakame::Service::LockQueue.new(nil)
    q.set('Apache', '12345')
    q.set('MySQL', '12345')
    q.set('MySQL2', '12345')
    q.set('Apache', '6789')
    q.set('LB', '6789')
    assert_equal(:runnable, q.test('12345'))
    assert_equal(:wait, q.test('6789'))
    assert_equal(:pass, q.test('unknown'))
    #puts q.inspect
    q.quit('12345')
    assert_equal(:pass, q.test('12345'))
    assert_equal(:runnable, q.test('6789'))
    #puts q.inspect
    q.set('Apache', '2345')
    q.set('LB', '2345')
    q.set('MySQL', '2345')
    assert_equal(:runnable, q.test('6789'))
    assert_equal(:wait, q.test('2345'))
    q.quit('2345')
    assert_equal(:runnable, q.test('6789'))
    assert_equal(:pass, q.test('2345'))
  end
end
