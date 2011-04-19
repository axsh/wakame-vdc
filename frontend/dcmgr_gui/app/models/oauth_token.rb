# -*- coding: utf-8 -*-
class OauthToken < BaseNew
  attr_accessor :token
  attr_accessor :secret

  def generate_keys
    self.token = OAuth::Helper.generate_key(40)[0,40]
    self.secret = OAuth::Helper.generate_key(40)[0,40]
  end
end