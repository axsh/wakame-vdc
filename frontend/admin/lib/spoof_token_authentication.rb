# -*- coding: utf-8 -*-
require 'base64'
require 'openssl'
module SpoofTokenAuthentication
  @config = Struct.new("Config", :expire, :authentication_token).new

  def self.config
    @config
  end

  # Generate the token from the parameter
  def self.generate(user_id, timestamp)
    Base64.encode64("#{OpenSSL::HMAC.digest(OpenSSL::Digest::SHA1::new, @config.authentication_token, "#{user_id}#{timestamp}")}").chomp
  end

  # return true or false as a result of checking the token.
  # exsample:
  # if SpoofTokenAuthentication.check_token(token, user_id, timestamp, expire)
  #   "Processing of a successful"
  # else
  #   "Processing of a error"
  # end
  def self.check_token(token, user_id, timestamp, expire=nil)
    expire = @config.expire if expire.nil? || expire.empty?
    # Check the expiration date of the token
    return false if Time.parse(timestamp) + expire.to_i < Time.now
    # compare the token that was decrypted with token
    return false if token != generate(user_id, timestamp)
    true
  end
end
