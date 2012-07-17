# -*- coding: utf-8 -*-

require 'erb'

module Dcmgr
  module Helpers
    module TemplateHelper

      def render_template(template_file_path, output_file_path, &block)
        unless File.exists?(output_file_path)
          render(template(template_file_path), output_file_path) do
            block.call
          end
        end
      end

      def render_remote_template(template_file_path, params, &block)
        begin
          temp = Tempfile::new(template_file_path, "/var/tmp/")
          output_file_path = temp.path

          render(template(template_file_path), output_file_path) do
            binding
          end

          config = File.read(output_file_path)

          EM.schedule do
            conn = Dcmgr.messaging.amqp_client
            channel = AMQP::Channel.new(conn)
            ex = channel.topic(params[:topic_name], params[:queue_options])
            begin
              channel = AMQP::Channel.new(conn)
              queue = AMQP::Queue.new(channel, params[:queue_name], :exclusive => false, :auto_delete => true)
              queue.bind(ex)
              queue.publish(config)
            rescue Exception => e
              logger.error(e.message)
            end
          end

          logger.info("Update #{template_file_path}")
        rescue ::Exception => e
          logger.error(e)
          raise 'Faild to bind HAProxy'
        ensure
          temp.close(true)
          logger.info("Delete config file: #{output_file_path}")
        end
      end

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      private
      def template(template_file_path)
        template_file_path = File.join(File.expand_path("../../../../",__FILE__),"/templates/#{self.class.instance_variable_get(:@template_base_dir)}",template_file_path)
        raise "template directory does not exists #{template_file_path}" unless File.exists?(template_file_path)
        template_file_path
      end

      def render(template_file_path, output_file_path, &block)
        erb = ERB.new(File.new(template_file_path).read, nil, '-')
        output = File.new(output_file_path, 'w+')
        output.puts(erb.result(block.call))
        output.close
        logger.debug("output config file #{output_file_path}")
        output
      end

      module ClassMethods
        def template_base_dir(dir_name)
          @template_base_dir = dir_name
        end
      end
    end
  end
end
