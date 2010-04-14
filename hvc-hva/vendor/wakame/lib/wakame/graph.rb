
module Wakame
  
  class Graph
    attr_accessor :edges

    def initialize
      @edges={}
    end
    
    def add_edge(v, c)
      return if v == c
      add_vertex(v)
      add_vertex(c)
      @edges[v][c]=1
    end

    def remove_edge(v, c)
      @edges[v].delete(c)
    end

    def has_edge?(v, c)
      @edges.has_key?(v) && @edges[v].has_key?(c)
    end

    def add_vertex(v)
      @edges[v] ||= {}
    end

    def remove_vertex(v)
      @edges.keys.each { |n|
        n.delete(v)
      }
      @edges.delete(v)
    end

    def parents(v)
      plist=[]
      @edges.each { |n, c|
        plist << n if c.has_key?(v)
      }
      plist
    end

    def children(v)
      @edges[v].keys
    end

    def inspect
      str="#{self}:"
      str << @edges.keys.sort.collect { |v|
        "#{v}=>#{@edges[v].keys.inspect}"
      }.join(', ')
      str
    end


    def level_layout(root)
      @vtx_ylevels = {root=>0}

      descend(root, 0)

      ycoord=Array.new(@vtx_ylevels.values.max)
      @vtx_ylevels.each { |v, lv|
        (ycoord[lv] ||= []) << v
      }
      
      ycoord
    end

    private
    def descend(v, ylevel=0)
      ylevel += 1
      @edges[v].keys.each { |c|
        @vtx_ylevels[c]=ylevel if @vtx_ylevels[c].nil? || @vtx_ylevels[c] < ylevel
        descend(c, ylevel)
      }
    end
  end
end
