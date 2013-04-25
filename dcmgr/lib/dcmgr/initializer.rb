# -*- coding: utf-8 -*-

module Dcmgr
  module Initializer

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def conf
        @conf
      end

      def load_conf(conf_class, files)
        path = files.find { |i| File.exists?(i) }
        abort("ERROR: Failed to load #{path}.") if path.nil?

        begin
          ::Dcmgr.instance_eval {
            @conf = conf_class.load(path)
          }
        rescue NoMethodError => e
          abort("Syntax Error: #{path}\n  #{e.backtrace.first} #{e.message}")
        rescue Fuguta::Configuration::ValidationError => e
          abort("Validation Error: #{path}\n  " +
                e.errors.join("\n  ")
                )
        end
      end

      def run_initializers(*files)
        raise "Complete the configuration prior to run_initializers()." if @conf.nil?

        @files ||= []
        if files.length == 0
          @files << "*"
        else
          @files = files
        end

        initializer_hooks.each { |n|
          n.call
        }
      end

      def initializer_hooks(&blk)
        @initializer_hooks ||= []
        if blk
          @initializer_hooks << blk
        end
        @initializer_hooks
      end
    end
  end
end
