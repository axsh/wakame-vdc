# -*- coding: utf-8 -*-

require 'sequel'
require 'yaml'

#TODO: Make sure :desc is filled in for every option
module Cli
  class AccountCli < Base
    namespace :account
    #M=Dcmgr::Models

    #no_tasks {
      #def before_task
        ## Setup DB connections and load paths for dcmgr_gui
        #root_dir = File.expand_path('../../../', __FILE__)
        
        ##get the database details
        ##TODO:get this path in a less hard-coded way?
        #content = File.new(File.expand_path('../../frontend/dcmgr_gui/config/database.yml', root_dir)).read
        #settings = YAML::load content
        
        ##load the database variables
        ##TODO: get environment from RAILS_ENV
        #db_environment = 'development'
        #db_adapter     = settings[db_environment]['adapter']
        #db_host        = settings[db_environment]['host']
        #db_name        = settings[db_environment]['database']
        #db_user        = settings[db_environment]['user']
        #db_pwd         = settings[db_environment]['password']
        
        ##Connect to the database
        #url = "#{db_adapter}://#{db_host}/#{db_name}?user=#{db_user}&password=#{db_pwd}"
        #db = Sequel.connect(url)
        
        ##load the cli environment
        #$LOAD_PATH.unshift File.expand_path('../../frontend/dcmgr_gui/config', root_dir)
        #$LOAD_PATH.unshift File.expand_path('../../frontend/dcmgr_gui/app/models', root_dir)
        ##require 'account'
        #require 'environment-cli'
        
        ##Associate the models with their respective database
        #Account.db = db
        #User.db = db
      #end
    #}

    desc "add [options]", "Create a new account."
    method_option :name, :type => :string, :aliases => "-n", :desc => "The name for the new account." #Maximum size: 255
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new account."
    method_option :description, :type => :string, :aliases => "-d", :desc => "The description for this account."
    #method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def add
      #Check if the data we got is valid
      if options[:name] != nil && options[:name].length > 255
        raise "Account name can not be longer than 255 characters."
      end
      if options[:description] != nil && options[:description].length > 100
        raise "Account description can not be longer than 100 chracters."
      end
      
      #Put them in the backend
      #fields = {:description => options[:description], :enabled => M::Account::ENABLED}
      #fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
      
      #new_uuid = super(M::Account,fields)

      ##This should never happen as long as the databases remain synchronized.
      #begin
        #raise "A uuid collision occurred. This means the account databases are not synchronized." if Account[new_uuid] != nil
      #rescue
        #M::Account[new_uuid].delete
        #raise 
      #end
      
      #Put them in the frontend
      #super(Account,{:uuid => new_uuid,:name => options[:name],:description => options[:description]})
      
      #puts new_uuid
      fields = {:name => options[:name],:description => options[:description], :enable => Account::ENABLED}
      fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
      puts super(Account,fields)
    end
    
    desc "show [UUID] [options]", "Show all accounts currently in the database"    
    method_option :deleted, :type => :boolean, :default => false, :aliases => "-d", :desc => "Show deleted accounts."
    def show(uuid = nil)
      if uuid
        #back_acc = M::Account[uuid] || raise(Thor::Error, "Unknown Account UUID: #{uuid}")
        acc = Account[uuid] || raise(Thor::Error, "Unknown Account UUID: #{uuid}")
        puts ERB.new(<<__END, nil, '-').result(binding)
Account UUID:
<%- if acc.class == Account -%>
  <%= acc.canonical_uuid %>
<%- else -%>
  <%= Account.uuid_prefix%>-<%= acc.uuid %>
<%- end -%>
Enabled:
<%- if acc.enable? -%>
  Yes
<%- else -%>
  No
<%- end -%>
<%- if acc.name -%>
Name:
  <%= acc.name %>
<%- end -%>
<%- if acc.description -%>
Description:
  <%= acc.description %>
<%- end -%>
<%- if acc.is_deleted -%>
Deleted at:
  <%= acc.deleted_at %>
<%- end -%>
<%- unless acc.users.empty? -%>
Associated users:
<%- acc.users.each { |row| -%>
  <%= row.canonical_uuid %>\t<%= row.name %>
<%- } -%>
<%- end -%>
__END
      else
        #This needs an "|| false" because options[:deleted] is usually nil which isn't the same as false
        acc = Account.filter(:is_deleted => (options[:deleted] || false )).all
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- acc.each { |row| -%>
<%- if row.class == Account -%>
<%= row.canonical_uuid %>\t<%= row.name %>
<%- else -%>
<%= Account.uuid_prefix%>-<%= row.uuid %>\t<%= row.name %>
<%- end -%>
<%- } -%>
__END
      end
    end
    
    desc "modify UUID [options]", "Modify an existing account."    
    method_option :name, :type => :string, :aliases => "-n", :desc => "The new name for the account." #Maximum size: 200    
    method_option :description, :type => :string, :aliases => "-d", :desc => "The new description for the account."
    #method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def modify(uuid)
      raise "Account name can not be longer than 255 characters." if options[:name] != nil && options[:name].length > 255
      raise "Description can not be longer than 100 characters." if options[:description] != nil && options[:description].length > 100
      super(Account,uuid,{:name => options[:name],:description => options[:description]})
      #super(M::Account,uuid,{:description => options[:description]})
    end
    
    #TODO: show account to confirm deletion
    desc "del UUID [options]", "Deletes an existing account."    
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def del(uuid)
      super(Account,uuid)
      #super(M::Account,uuid)
      
      puts "Account #{uuid} has been deleted." if options[:verbose]
    end
    
    desc "enable UUID [options]", "Enable an account."
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def enable(uuid)
      to_enable = Account[uuid]
      Error.raise("Unknown frontend account UUID: #{uuid}", 100) if to_enable == nil or to_enable.is_deleted
      #to_enable_back = M::Account[uuid] || Error.raise("Unknown backend account UUID: #{uuid}", 100)
      
      if to_enable.enable?# && to_enable_back.enable?
        puts "Account #{uuid} is already enabled." if options[:verbose]
      else      
        to_enable.enable = Account::ENABLED
        to_enable.updated_at = Time.now.utc.iso8601
        to_enable.save   
	        
        #to_enable_back.enabled = Dcmgr::Models::Account::ENABLED
        #to_enable_back.updated_at = Time.now.utc.iso8601
        #to_enable_back.save
	
        puts "Account #{uuid} has been enabled." if options[:verbose]
      end
    end
    
    desc "disable UUID [options]", "Disable an account."    
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def disable(uuid)
      to_disable = Account[uuid]
      UnknownUUIDError.raise(uuid) if to_disable == nil or to_disable.is_deleted
      #to_disable_back = M::Account[uuid] || Error.raise("Unknown backend account UUID: #{uuid}", 100)
      
      if to_disable.disable? #&& to_disable_back.disable?
        puts "Account #{id} is already disabled." if options[:verbose]
      else
        to_disable.enable = Account::DISABLED
        to_disable.updated_at = Time.now.utc.iso8601
        to_disable.save
        
        #to_disable_back.enabled = M::Account::DISABLED
        #to_disable_back.updated_at = Time.now.utc.iso8601
        #to_disable_back.save
        
        puts "Account #{uuid} has been disabled." if options[:verbose]
      end
    end
    
    desc "associate UUID", "Associate an account with a user or multiple users."
    method_option :users, :type => :array, :required => true, :aliases => "-u", :desc => "The uuid of the users to associate with the account. Any non-existing uuid will be ignored"    
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def associate(uuid)      
      account = Account[uuid] || UnknownUUIDError.raise(uuid)
      
      options[:users].each { |u|        
        if User[u].nil?
          puts "Unknown user UUID: #{u}" if options[:verbose]
        elsif !account.users.index(User[u]).nil?
          puts "Account #{uuid} is already associated with user #{u}." if options[:verbose]
        else
          account.add_user(User[u])
          
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
        elsif account.users.index(User[u]).nil?
          puts "Account #{uuid} is not associated with user #{u}." if options[:verbose]
        else
          account.remove_user(user)
          
          puts "Account #{uuid} successfully dissociated from user #{u}." if options[:verbose]
          
          if account.uuid == user.primary_account_id
            user.primary_account_id = nil
            user.save
            puts "This was user #{u}'s primary account. Has been set to Null now." if options[:verbose]
          end
        end
      }
    end
    
    #desc "quota UUID [options]","Set quota settings for an account."
    #method_option :weight, :type => :numeric, :aliases => "-w", :desc => "The instance total weight to set this account's quota to."
    #method_option :size, :type => :numeric, :aliases => "-s", :desc => "The volume total size to set this account's quota to."
    #def quota(uuid)
      #account = M::Account[uuid] || UnknownUUIDError.raise(uuid)
      #account.quota.instance_total_weight = options[:weight] unless options[:weight].nil?
      #account.quota.volume_total_size = options[:size] unless options[:size].nil?
      #account.quota.updated_at = Time.now.utc.iso8601
      #account.quota.save
    #end
    
  end
end
