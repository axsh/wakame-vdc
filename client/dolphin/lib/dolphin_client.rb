# -*- coding: utf-8 -*-

module DolphinClient

  def self.domain=(domain)
    @domain = domain
  end

  def self.domain
    @domain
  end

  autoload :API, 'dolphin_client/api'
  autoload :Event, 'dolphin_client/event'
  autoload :Notification, 'dolphin_client/notification'

end
