require 'oauth'
class OauthConsumer < BaseNew
  
  many_to_one :account
  
  with_timestamps
  
  inheritable_schema do
    primary_key :id, :type=>Integer
    String :key, :null => false, :size => 40
    String :secret, :null => false, :size => 40
    Integer :account_id, :null => false, :unique=>true
    index :key, :unique=>true
  end
end
