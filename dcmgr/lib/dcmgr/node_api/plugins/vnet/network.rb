# -*- coding: utf-8 -*-

module Dcmgr::NodeApi::Plugins::Vnet
  class Network
    class << self
      def before_create
        puts :before_create
      end

      def after_create
        puts :after_create
      end
    end
  end
end
