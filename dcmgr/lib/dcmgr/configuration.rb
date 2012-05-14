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

      def config
        self
      end
    end

    class << self
      def initialize_callbacks
        @initialize_callbacks
      end

      # Show warning message if the old parameter is set.
      def deprecated_warn_param(old_name, message=nil, &blk)
        on_param_create_hook do |param_name, opts|
          warn_msg = message || "WARN: Deprecated parameter: #{old_name}. Please use '#{param_name}'."
          
          alias_param old_name, param_name
          self.const_get(:DSL).class_eval %Q{
            def #{old_name}(v)
              STDERR.puts "#{warn_msg}"
              #{param_name.to_s}(v)
            end
          }
        end
      end

      # Raise an error if the old parameter is set.
      def deprecated_error_param(old_name, message=nil)
        on_param_create_hook do |param_name, opts|
          err_msg = message || "ERROR: Parameter is no longer supported: #{old_name}. Please use '#{param_name}'."
          
          alias_param old_name, param_name
          self.const_get(:DSL).class_eval %Q{
            def #{old_name}(v)
              raise "#{err_msg}"
            end
          }
        end
      end

      def alias_param (alias_name, ref_name)
        # getter
        self.class_eval %Q{
          # Ruby alias show error if the method to be defined later is
          # set. So create method to call the reference method.
          def #{alias_name.to_s}()
            #{ref_name}()
          end
        }
        
        # DSL setter
        self.const_get(:DSL).class_eval %Q{
          def #{alias_name}(v)
            #{ref_name.to_s}(v)
          end
          alias_method :#{alias_name.to_s}=, :#{alias_name.to_s}
        }
      end

      def param(name, opts={})
        opts = opts.merge(@opts)
        
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

        @on_param_create_hooks.each { |blk|
          blk.call(name.to_s.to_sym, opts)
        }
        self.const_get(:DSL).class_eval %Q{
          def #{name}(v)
            @config["#{name.to_s}".to_sym] = v
          end
          alias_method :#{name.to_s}=, :#{name.to_s}
        }

        @opts.clear
        @on_param_create_hooks.clear
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

      # Helper method defines "module DSL" under the current conf class.
      #
      # This does mostly same things as "module DSL" but using
      # "module" statement get the "DSL" constant defined in unexpected
      # location if you combind to use with other Ruby DSL syntax.
      #
      # Usage:
      # class Conf1 < Configuration
      #   DSL do
      #   end
      # end
      def DSL(&blk)
        self.const_get(:DSL).class_eval(&blk)
        self
      end

      private
      def inherited(klass)
        super
        klass.const_set(:DSL, Module.new)
        klass.instance_eval {
          @initialize_callbacks = []
          @opts = {}
          @on_param_create_hooks = []
        }

        dsl_mods = []
        c = klass
        while c < Configuration && c.superclass.const_defined?(:DSL)
          parent_dsl = c.superclass.const_get(:DSL)
          if parent_dsl && parent_dsl.class === Module
            dsl_mods << parent_dsl
          end
          c = c.superclass
        end
        # including order is ancestor -> descendants
        dsl_mods.reverse.each { |i|
          klass.const_get(:DSL).__send__(:include, i)
        }
      end

      def on_param_create_hook(&blk)
        @on_param_create_hooks << blk
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
