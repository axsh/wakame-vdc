# -*- coding: utf-8 -*-

module Dcmgr
  class Configuration

    class ValidationError < StandardError
      attr_reader :errors
      def initialize(errors)
        super("validation error")
        @errors = errors
      end
    end
    
    def self.walk_tree(conf, &blk)
      raise ArgumentError unless conf.is_a?(Configuration)
      
      blk.call(conf)
      conf.config.values.each { |c|
        case c
        when Configuration
          walk_tree(c, &blk)
        when Hash, Array
          c.values.each { |c1| walk_tree(c1, &blk) if c1.is_a?(Configuration) }
        end
      }
    end

    class Loader
      def initialize(conf)
        @conf = conf
      end

      def load(path)
        buf = String.new
        case path
        when String
          raise "does not exist: #{path}" unless File.exists?(path)
          buf = File.read(path)
        when IO
          path.lines.each { |l| buf += l }
        else
          raise "Unknown type: #{path.class}"
        end

        @conf.parse_dsl do |me|
          me.instance_eval(buf, path.to_s)
        end
      end

      def validate
        errors = []
        Configuration.walk_tree(@conf) do |c|
          c.validate(errors)
        end
        raise ValidationError, errors if errors.size > 0
      end
    end

    class DSLProxy
      def initialize(subject)
        @subject = subject
        @config = subject.config
      end
    end

    class << self
      def initialize_callbacks
        @initialize_callbacks
      end
      
      def param(name, opts={})
        case opts[:default]
        when Proc
          # create getter method if proc is set as default value
          self.class_exec {
            define_method(name.to_s.to_sym, &opts[:default])
          }
        else
          @initialize_callbacks << proc { |c|
            @config[name.to_s.to_sym] = opts[:default]
          }
        end
        
        self.const_get(:DSL).class_eval %Q{
          def #{name}(v)
            @config["#{name.to_s}".to_sym] = v
          end

          def #{name}=(v)
            #{name}(v)
          end
        }
      end

      def load(*paths)
        c = self.new

        l = Loader.new(c)

        paths.each { |path|
          l.load(path)
        }
        l.validate
        
        c
      end

      private
      def inherited(klass)
        klass.const_set(:DSL, Module.new)
        klass.instance_eval {
          @initialize_callbacks = []
        }
      end
    end

    attr_reader :config
    
    def initialize
      @config = {}

      self.class.initialize_callbacks.each { |c|
        self.instance_eval(&c)
      }
    end

    def validate(errors)
    end

    def parse_dsl(&blk)
      dsl = self.class.const_get(:DSL)
      raise "DSL module was not found" unless dsl && dsl.is_a?(Module)
      
      cp_class = DSLProxy.dup
      cp_class.__send__(:include, dsl)
      cp = cp_class.new(self)

      cp.instance_eval(&blk)
      
      self
    end

    private
    def method_missing(m, *args)
      if @config.has_key?(m.to_sym)
        @config[m.to_sym]
      elsif @config.has_key?(m.to_s)
        @config[m.to_s]
      else
        super
      end
    end

  end
end
