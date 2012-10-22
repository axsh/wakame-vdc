# -*- coding: utf-8 -*-

require 'erb'

module Dcmgr
  module Helpers
    module TemplateHelper

      TEMPLATE_ROOT_DIR = File.expand_path("../../../../templates", __FILE__).freeze

      def render_template(template_file_name, output_file_path, bindscope=Kernel.binding)
        unless File.exists?(output_file_path)
          File.open(output_file_path, 'w+') do |f|
            f.write(render(template_file_name, bindscope))
          end
        end
      end

      def bind_template(template_file_name, bindscope=Kernel.binding)
        render(template_file_name, bindscope)
      end

      def template_real_path(template_file_name)
        self.class.template_real_path(template_file_name)
      end

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      private
      def render(template_file_name, bindscope)
        raise ArgumentError unless bindscope.is_a?(Binding)
        template_file_path = template_real_path(template_file_name)
        raise "template file does not exist: #{template_file_path}" unless File.exists?(template_file_path)

        ERB.new(File.read(template_file_path), nil, '-').result(bindscope)
      end

      module ClassMethods
        # Set class local subdirectory name from templates/ folder.
        def template_base_dir(dir_name)
          basedir = File.join(TEMPLATE_ROOT_DIR, dir_name)
          unless File.directory?(basedir)
            raise "Unable to find the template base directory: #{basedir}"
          end
          @template_base_dir = dir_name
        end

        # Build absolute path to the template file.
        #
        # template_real_path('xxx.txt') => '/var/lib/xxxx/templates/base_dir/xxx.txt'
        def template_real_path(template_file_name)
          raise "template_base_dir is unset for the class: #{self}" if @template_base_dir.nil?
          File.join(TEMPLATE_ROOT_DIR, @template_base_dir, template_file_name)
        end
      end
    end
  end
end
