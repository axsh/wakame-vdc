# -*- coding: utf-8 -*-

#TODO: Make sure :desc is filled in for every option
module Cli
  class AccountCli < Base
    namespace :account

    desc "add [options]", "Create a new account."
    method_option :name, :type => :string, :aliases => "-n", :required => true, :desc => "The name for the new account."
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new account."
    method_option :description, :type => :string, :aliases => "-d", :default => "", :desc => "The description for this account."
    def add
      #Check if the data we got is valid
      if options[:name] != nil && options[:name].length > 255
        raise "Account name can not be longer than 255 characters."
      end
      
      fields = {:name => options[:name],:description => options[:description]}
      fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
      puts super(Account,fields)
    end
    
    desc "show [UUID] [options]", "Show all accounts currently in the database"    
    method_option :with_deleted, :type => :boolean, :default => false, :aliases => "-d", :desc => "Show deleted accounts."
    def show(uuid = nil)
      if uuid
        ds = Account.by_uuid(uuid)
        if options[:with_deleted]
          ds = ds.with_deleted
        end
        acc = ds.first || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= acc.canonical_uuid %>
Name: <%= acc.name %>
Enabled: <%= acc.enabled %>
Created: <%= acc.created_at %>
Updated: <%= acc.updated_at %>
<%- if acc.deleted_at -%>
Deleted: <%= acc.deleted_at %>
<%- end -%>
<%- unless acc.users.empty? -%>
Associated users:
<%- acc.users.each { |row| -%>
  <%= row.canonical_uuid %>\t<%= row.name %>
<%- } -%>
<%- end -%>
<%- if acc.description -%>
<%- unless acc.account_quota.empty? -%>
Quota:
<%- acc.account_quota.each { |aq| -%>
  <%= aq.quota_type %> <%= aq.quota_value %>
<%- } -%>
<%- end -%>
Description:
<%= acc.description %>
<%- end -%>
__END
      else
        ds = Account.dataset
        if options[:with_deleted]
          ds = ds.with_deleted
        end
        table = [['UUID', 'Name', 'Created', 'Enabled']]
        if options[:with_deleted]
          table[0] << 'Deleted'
        end
        ds.each {|u|
          row = [u.canonical_uuid, u.name, u.created_at.to_s, u.enabled.to_s]
          if options[:with_deleted]
            row << (!u.deleted_at.nil?).to_s
          end
          
          table << row
        }
        if table.size > 1
          shell.print_table(table)
        end
      end
    end
    
    desc "modify UUID [options]", "Modify an existing account."    
    method_option :name, :type => :string, :aliases => "-n", :desc => "The new name for the account."
    method_option :description, :type => :string, :aliases => "-d", :desc => "The new description for the account."
    def modify(uuid)
      raise "Account name can not be longer than 255 characters." if options[:name] != nil && options[:name].length > 255
      raise "Description can not be longer than 100 characters." if options[:description] != nil && options[:description].length > 100
      super(Account,uuid,{:name => options[:name],:description => options[:description]})
    end
    
    #TODO: show account to confirm deletion
    desc "del UUID [options]", "Deletes an existing account."    
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def del(uuid)
      to_do = Account[uuid]
      Error.raise("Unknown frontend account UUID: #{uuid}", 100) if to_do == nil

      super(Account,uuid)
      
      puts "Account #{uuid} has been deleted." if options[:verbose]
    end
    
    desc "enable UUID [options]", "Enable an account."
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def enable(uuid)
      to_enable = Account[uuid]
      Error.raise("Unknown frontend account UUID: #{uuid}", 100) if to_enable == nil
      
      if to_enable.enable?
        puts "Account #{uuid} is already enabled." if options[:verbose]
      else
        to_enable.enabled = true
        to_enable.save_changes

        puts "Account #{uuid} has been enabled." if options[:verbose]
      end
    end
    
    desc "disable UUID [options]", "Disable an account."    
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def disable(uuid)
      to_disable = Account[uuid]
      UnknownUUIDError.raise(uuid) if to_disable == nil
      
      if to_disable.disable?
        puts "Account #{id} is already disabled." if options[:verbose]
      else
        to_disable.enabled = false
        to_disable.save_changes
        
        puts "Account #{uuid} has been disabled." if options[:verbose]
      end
    end
    
    desc "associate UUID", "Associate an account with a user or multiple users."
    method_option :users, :type => :array, :required => true, :aliases => "-u", :desc => "The uuid of the users to associate with the account. Any non-existing uuid will be ignored"    
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def associate(uuid)      
      account = Account[uuid] || UnknownUUIDError.raise(uuid)
      
      options[:users].each { |u|
        user = User[u]
        if user.nil?
          puts "Unknown user UUID: #{u}" if options[:verbose]
        elsif !account.users_dataset.filter(:users_accounts__user_id=>user.id).empty?
          puts "Account #{uuid} is already associated with user #{u}." if options[:verbose]
        else
          account.add_user(user)
          if user.primary_account_id.nil?
            user.primary_account_id = account.uuid
            user.save_changes
          end
          
          puts "Account #{uuid} successfully associated with user #{u}." if options[:verbose]
        end
      }
    end
    
    desc "dissociate UUID", "Dissociate an account from a user or multiple users."
    method_option :users, :type => :array, :required => true, :aliases => "-u", :desc => "The uuid of the users to dissociate from the account. Any non-existing or non numeral id will be ignored"
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def dissociate(uuid)
      account = Account[uuid] || UnknownUUIDError.raise(uuid)
      
      options[:users].each { |u|
        user = User[u]
        if user.nil?
          puts "Unknown user UUID: #{u}" if options[:verbose]
        elsif account.users_dataset.filter(:users_accounts__user_id=>user.id).empty?
          puts "Account #{uuid} is not associated with user #{u}." if options[:verbose]
        else
          account.remove_user(user)
          
          puts "Account #{uuid} successfully dissociated from user #{u}." if options[:verbose]
          
          if account.uuid == user.primary_account_id
            user.primary_account_id = nil
            user.save_changes
            puts "This was user #{u}'s primary account. Has been set to Null now." if options[:verbose]
          end
        end
      }
    end
    
    class OAuthOperation < Base
      namespace :oauth
      
      desc "add ACCOUNT_UUID", "Generate/Add OAuth key and secret"
      def add(account_uuid)
        account = Account[account_uuid] || UnknownUUIDError.raise(account_uuid)
        oauth = OauthConsumer.new
        account.add_oauth_consumer(oauth)
        puts "Access key: #{oauth.key}"
        puts "Secret key: #{oauth.secret}"
      end

      desc "del ACCESSKEY", "Delete OAuth access key"
      def del(access_key)
        oauth = OauthConsumer.find(:key=>access_key) || UnknownUUIDError.raise(uuid)
        oauth.destroy
      end

      desc "show ACCOUNT_UUID|ACCESSKEY", "List/Show OAuth access key"
      def show(key_or_account)
        if Account.check_uuid_format(key_or_account)
          account = Account[key_or_account] || UnknownUUIDError.raise(uuid)
          puts ERB.new(<<__END, nil, '-').result(binding)
Account ID: <%= account.canonical_uuid %>
<%- account.oauth_consumers.each { |consumer| -%>
-----------------
Access Key: <%= consumer.key %>
Secret Key: <%= consumer.secret %>
<%- } -%>
__END
        else
          consumer = OauthConsumer.find(:key=>key_or_account) || Error.raise("Unknown OAuth Access Key: #{key_or_account}", 100)
          puts ERB.new(<<__END, nil, '-').result(binding)
Access Key: <%= consumer.key %>
Secret Key: <%= consumer.secret %>
Created: <%= consumer.created_at %>
Updated: <%= consumer.updated_at %>
Account ID: <%= consumer.account.canonical_uuid %>
__END
        end
      end
    end
    
    register OAuthOperation, 'oauth', "oauth [#{OAuthOperation.tasks.keys.join(', ')}] UUID [options]", "Set/Unset quota values for the account"

    class QuotaOperation < Base
      namespace :quota
      
      desc "set UUID TYPE VALUE", "Set quota to the account."
      def set(uuid, quota_type, quota_value)
        account = Account[uuid] || UnknownUUIDError.raise(uuid)

        account.add_account_quota(AccountQuota.new(:quota_type=>quota_type,
                                                   :quota_value=>quota_value.to_f))
      end

      desc 'drop UUID TYPE', "Drop quota from the account."
      def drop(uuid, quota_type)
        account = Account[uuid] || UnknownUUIDError.raise(uuid)
        account.account_quota_dataset.filter(:quota_type=>quota_type).each {|aq| aq.destroy }
      end

      desc 'dropall UUID', "Drop all quota from the account."
      def dropall(uuid)
        account = Account[uuid] || UnknownUUIDError.raise(uuid)
        account.remove_all_account_quota
      end
    end

    register QuotaOperation, 'quota', "quota [#{QuotaOperation.tasks.keys.join(', ')}] UUID [options]", "Set/Unset quota values for the account"
    
  end
end
