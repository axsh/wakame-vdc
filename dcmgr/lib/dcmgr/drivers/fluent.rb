module Dcmgr
  module Drivers
    class Fluent

      include Dcmgr::Logger
      include Dcmgr::Helpers::TemplateHelper

      CONFIG_FILENAME = 'fluent.conf'.freeze

      @template_base_dir = "fluent"

      def initialize
        @template_file_name = CONFIG_FILENAME
        @output_file_name = CONFIG_FILENAME
      end

      def set_alarms(alarms)
        @alarms = []
        alarms.each do |alarm|
          @alarms << {
            :resource_id => alarm[:resource_id],
            :alarm_id => alarm[:alarm_id],
            :tag => alarm[:tag],
            :match_pattern => alarm[:match_pattern],
            :evaluation_periods => alarm[:evaluation_periods]
          }
        end
      end

      def generate_config
        output_file_path = File.join(Dcmgr.conf.logging_service_tmp, @output_file_name)
        if File.exists?(output_file_path)
          FileUtils.rm(output_file_path)
        end
        render_template(@template_file_name, output_file_path, binding)
      end
    end
  end
end
