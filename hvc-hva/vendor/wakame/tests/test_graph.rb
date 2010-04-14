
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'

require 'test/unit'
require 'wakame/graph'

WAKAME_ROOT="#{File.dirname(__FILE__)}/.."

class TestGraph < Test::Unit::TestCase
  def test_graph1
    g = Wakame::Graph.new
    g.add_edge(0, 1) # LB
    g.add_edge(0, 2) # APP
    g.add_edge(0, 3) # WWW
    g.add_edge(0, 4) # MySQL
    g.add_edge(0, 5) # LB0
    g.add_edge(0, 6) # MySQL_Slave
    
    g.remove_edge(0, 1)
    g.add_edge(2, 1) # APP -> LB
    g.add_edge(3, 1) # WWW -> LB
    g.remove_edge(0, 2)
    g.add_edge(4, 2) # MySQL -> APP
    g.remove_edge(0, 5)
    g.add_edge(1, 5) # LB -> LB0
    g.add_edge(6, 2) # MySQL_Slave -> APP
    g.remove_edge(0, 4)
    g.add_edge(6, 4) # MySQL_Slave -> MySQL
    
    
    assert_equal([[3], [1], [5]], g.level_layout(3))
    assert_equal([[0], [3, 6], [2], [3], [1], [5]], g.level_layout(0))

  end
end
