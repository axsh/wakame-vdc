module Dcmgr
  module Drivers
    class Stunnel
      include Dcmgr::Logger
      include Dcmgr::Helpers::TemplateHelper

      @template_base_dir = "stunnel"

      attr_accessor :protocol, :accept_port, :connect_port
      def initialize
      end

    end
  end
end
