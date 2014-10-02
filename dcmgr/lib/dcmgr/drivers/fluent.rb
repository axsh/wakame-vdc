require "csv"
require "uri"

module Dcmgr
  module Drivers
    class Fluent

      include Dcmgr::Logger
      include Dcmgr::Helpers::TemplateHelper
      include Dcmgr::Helpers::CliHelper

      @template_base_dir = "fluent"

      def initialize
        @template_file_name = 'fluent.conf'
        @output_file = Dcmgr::Configurations.hva.logging_service_conf
        @dolphin_server_uri = Dcmgr::Configurations.hva.dolphin_server_uri
        @max_read_message_bytes = Dcmgr::Configurations.hva.logging_service_max_read_message_bytes
        @max_match_count = Dcmgr::Configurations.hva.logging_service_max_match_count
      end

      def set_alarms(alm)
        @alarms = []
        alm.each do |a|
          values = []
          values << a[:resource_id]
          values << a[:alarm_id]
          values << a[:tag]
          values << a[:match_pattern]
          values << a[:notification_periods]
          values << a[:enabled]
          values << a[:alarm_action]
          values << a[:display_name]
          @alarms << values.to_csv.strip
        end
      end

      def generate_config
        if File.exists?(@output_file)
          FileUtils.rm(@output_file)
        end
        render_template(@template_file_name, @output_file, binding)
      end

      def reload
        if Dcmgr::Configurations.hva.logging_service_reload
          sh("#{Dcmgr::Configurations.hva.logging_service_reload}")
          logger.info("Reload fluent with #{@output_file}")
        else
          logger.error("Failed to reload fluent. Not found #{Dcmgr::Configurations.hva.logging_service_reload}")
        end
      end

    end
  end
end
