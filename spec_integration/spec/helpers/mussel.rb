# -*- coding: utf-8 -*-

module Mussel
  MUSSEL_PATH='/opt/axsh/wakame-vdc/client/mussel'
  def self.exec(args)
    system("#{MUSSEL_PATH}/mussel.sh #{args}")
  end
end
