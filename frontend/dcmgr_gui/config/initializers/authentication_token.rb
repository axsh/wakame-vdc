# Be sure to restart your server when you modify this file.

# Your authentication token for verifying the integrity of signed token.
# If you change this key, all old signed token will become invalid!
# Make sure the token is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# rails console
# >ActiveSupport::SecureRandom.hex(30)
# => '404ff8b3659da8e805e0b67581c91e950b2faccea40ce5f63562a96771f1'
# Change sta.authentication_token = '404ff8b3659da8e805e0b67581c91e950b2faccea40ce5f63562a96771f1'
require 'spoof_token_authentication'
sta = SpoofTokenAuthentication.config
sta.expire = 3600
sta.authentication_token = '404ff8b3659da8e805e0b67581c91e950b2faccea40ce5f63562a96771f1'
