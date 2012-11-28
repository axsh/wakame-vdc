module Dcmgr
  module Drivers
    class Stud
      include Dcmgr::Logger
      include Dcmgr::Helpers::TemplateHelper

      @template_base_dir = "stud"

      attr_accessor :protocol, :accept_port, :connect_port
      def initialize
      end

    end
  end
end
