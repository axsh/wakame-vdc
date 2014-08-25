# -*- coding: utf-8 -*-

module Mussel
  MUSSEL_PATH='/opt/axsh/wakame-vdc/client/mussel'
  MUSSEL = "#{MUSSEL_PATH}/mussel.sh"

  class Base
    class << self
      def class_name
        self.name.split("::").last.downcase
      end

      def create(params)
        system("#{params}") if params
        JSON.parse(`#{MUSSEL} #{class_name} create`)
      end

      def destroy(params)
        system("#{params}") if params
        JSON.parse(`#{MUSSEL} #{class_name} destroy`)
      end
    end
  end
end
