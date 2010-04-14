

$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_master.rb'

require 'wakame'

require 'test/unit'
require 'wakame'
require 'wakame/template'
require 'wakame/service'
require 'wakame/event'
require 'wakame/event_dispatcher'

class TestTemplate < Test::Unit::TestCase
  class DummyAgent
    def agent_id
      'safasdfadsf'
    end

    def agent_ip
      '127.0.0.1'
    end

    def services
      {'aaa'=>nil}
    end
    
    def has_service_type?(n)
      false
    end
  end

  class A < Wakame::Service::Resource
    def basedir
      './tests/'
    end
    
    def render_config(template)
      template.cp(%w(conf/a conf/b conf/c))
    end
  end

  def test_render
    cluster = Wakame::Service::ServiceCluster.new(nil) { |c|
      c.add_service(A.new)
    }
    cluster.launch 


    agent = DummyAgent.new
    cluster.each_instance { |n|
      n.bind_agent(agent)

      tmpl = Wakame::Template.new(n)
      tmpl.render_config
      assert(File.exists?(File.join(tmpl.tmp_basedir, 'conf/a')))
      assert(File.exists?(File.join(tmpl.tmp_basedir, 'conf/b')))
      assert(File.exists?(File.join(tmpl.tmp_basedir, 'conf/c')))
      tmpl.cleanup
      assert(File.directory?(tmpl.tmp_basedir) == false )
    }

  end
end
