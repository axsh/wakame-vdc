# -*- coding: utf-8 -*-
class OauthConsumer < BaseNew
  with_timestamps
  
  many_to_one :account
end
