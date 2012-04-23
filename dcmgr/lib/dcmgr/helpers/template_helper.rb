# -*- coding: utf-8 -*-

require 'erb'

module Dcmgr
  module Helpers
    module TemplateHelper
      def render_template(template_file_path, output_file_path, &block)
        # generate config file
        unless File.exists?(output_file_path)
          erb = ERB.new(File.new(template_file_path).read, nil, '-')
          output = File.new(output_file_path, 'w+')
          output.puts(erb.result(block.call))
          output.close
          logger.debug("output config file #{output_file_path}")
        end
      end
    end
  end
end
