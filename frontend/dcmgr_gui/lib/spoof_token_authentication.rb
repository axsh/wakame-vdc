# -*- coding: utf-8 -*-
require 'base64'
require 'openssl'
module SpoofTokenAuthentication
  # Decrypts the token from the parameter
  def generate(data)
    Base64.encode64("#{OpenSSL::HMAC.digest(OpenSSL::Digest::SHA1::new, DcmgrGui::Application.config.authentication_token, data)}")
  end

  # return true or false as a result of checking the token.
  # exsample:
  # if SpoofTokenAuthentication.check_token(token, user_id, timestamp, expire)
  #   "Processing of a successful"
  # else
  #   "Processing of a error"
  # end
  def check_token(token, user_id, timestamp, expire)
    # Check the expiration date of the token
    return false if DateTime.parse(timestamp).since(expire.to_i) < DateTime.now
    # compare the token that was decrypted with token
    return false if token != generate("#{user_id}#{timestamp}#{expire}")
    true
  end

  module_function :generate, :check_token
end

