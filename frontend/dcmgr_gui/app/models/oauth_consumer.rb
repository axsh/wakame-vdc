# -*- coding: utf-8 -*-

require 'oauth'

class OauthConsumer < BaseNew
  with_timestamps
  
  many_to_one :account

  private
  def before_validation
    self[:key] ||= OAuth::Helper.generate_key(40)[0,40]
    self[:secret] ||= OAuth::Helper.generate_key(40)[0,40]
    super
  end
end
