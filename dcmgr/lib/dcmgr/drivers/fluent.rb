module Dcmgr
  module Drivers
    class Fluent

      include Dcmgr::Logger
      include Dcmgr::Helpers::TemplateHelper
      include Dcmgr::Helpers::CliHelper

      @template_base_dir = "fluent"

      def initialize
        @template_file_name = 'fluent.conf'
        @output_file = Dcmgr.conf.logging_service_conf
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
        if File.exists?(@output_file)
          FileUtils.rm(@output_file)
        end
        render_template(@template_file_name, @output_file, binding)
      end

      def reload
        if Dcmgr.conf.logging_service_reload
          sh("#{Dcmgr.conf.logging_service_reload} reload")
          logger.info("Reload fluent with #{@output_file}")
        else
          logger.error("Failed to reload fluent. Not found #{Dcmgr.conf.logging_service_reload}")
        end
      end

    end
  end
end
