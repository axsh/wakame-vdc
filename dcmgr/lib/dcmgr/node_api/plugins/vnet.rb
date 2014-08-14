# -*- coding: utf-8 -*-

module Dcmgr::NodeApi::Plugins
  module Vnet
    Dir["#{File.dirname(__FILE__)}/vnet/*.rb"].each { |f| require f }
  end

  register(Vnet)
end
