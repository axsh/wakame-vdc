# -*- coding: utf-8 -*-

require 'erb'

module Dcmgr
  module Helpers
    module TemplateHelper
      def render_template(template_file_path, output_file_path, &block)
        template_file_path = File.join(File.expand_path("../../../../",__FILE__),"/templates/#{self.class.instance_variable_get(:@template_base_dir)}",template_file_path)
        raise "template directory does not exists #{template_file_path}" unless File.exists?(template_file_path)
        # generate config file
        unless File.exists?(output_file_path)
          erb = ERB.new(File.new(template_file_path).read, nil, '-')
          output = File.new(output_file_path, 'w+')
          output.puts(erb.result(block.call))
          output.close
          logger.debug("output config file #{output_file_path}")
        end
      end
      
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        def template_base_dir(dir_name)
          @template_base_dir = dir_name
        end
      end
    end
  end
end
