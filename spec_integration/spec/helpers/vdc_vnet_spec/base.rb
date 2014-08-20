# -*- coding: utf-8 -*-

module VdcVnetSpec
  MUSSEL_PATH='/opt/axsh/wakame-vdc/client/mussel'
  MUSSEL = "#{MUSSEL_PATH}/mussel.sh"

  class Base
    class << self
      def class_name
        self.name.split("::").last.downcase
      end

      def create(params)
        system("#{params}") if params
        aa = system("#{MUSSEL} #{class_name} create")
      end
    end
  end
end
