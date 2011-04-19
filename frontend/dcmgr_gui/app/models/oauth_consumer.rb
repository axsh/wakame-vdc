require 'oauth'
class OauthConsumer < BaseNew
  
  many_to_one :user
  one_to_many :tokens, :class => "OauthToken"
  one_to_many :access_tokens
  one_to_many :oauth2_verifiers
  one_to_many :oauth_tokens
  
  with_timestamps
  
  inheritable_schema do
    primary_key :id, :type=>Integer
    String :key, :null => true, :size => 40
    String :secret, :null => true, :size => 40
    Integer :user_id, :null => true, :unique=>true
    index :key, :unique=>true
  end
end
