# -*- coding: utf-8 -*-

require 'sequel'
require 'yaml'

#TODO: Print only the first line of an exception?
module Cli
  class UserCli < Base
    namespace :user
    
    PASSWD_TABLE='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('').freeze
    
    desc "add [options]", "Create a new user."
    method_option :name, :type => :string, :required => true, :aliases => "-n", :desc => "The name for the new user." #Maximum size: 200
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new user."
    method_option :login_id, :type => :string, :aliases => "-l", :desc => "Optional: The login_id for the new user." #Maximum size: 255
    method_option :password, :type => :string, :aliases => "-p", :desc => "The password for the new user." #Maximum size: 255
    method_option :primary_account_id, :type => :string, :aliases => "-a", :desc => "Optional: The primary account to associate this user with." #Maximum size: 255
    def add
      if options[:name].length > 200
        Error.raise("User name can not be longer than 200 characters", 100)
      elsif options[:login_id] != nil && options[:login_id].length > 255
        Error.raise("User login_id can not be longer than 255 characters",100)
      elsif options[:password] != nil && options[:password].length > 255
        Error.raise("User password can not be longer than 255 characters", 100)
      elsif options[:primary_account_id] != nil && options[:primary_account_id].length > 255
        Error.raise(Thor::Error, "User primary_account_id can not be longer than 255 characters",100)
      else
        #Check if the primary account uuid exists
        Error.raise("Unknown Account UUID #{options[:primary_account_id]}",100) if options[:primary_account_id] != nil && Account[options[:primary_account_id]].nil?
        
        #The login id is needed to log into the web ui. Therefore we set it to name if it isn't provided.
        if options[:login_id].nil?
          login_id = options[:name]
        else
          login_id = options[:login_id]
        end
        
        #Check if username is available
        Error.raise("Login id already in use: '#{login_id}'.",100) unless User.find(:name => login_id).nil?
        
        #Generate password if password is null.
        passwd = options[:password] || Array.new(12) do PASSWD_TABLE[rand(PASSWD_TABLE.size)]; end.join
        
        #Encrypt the password
        pwd_hash = User.encrypt_password(passwd)
        
        #Put them in there
        fields = {:name => options[:name], :login_id => login_id, :password => pwd_hash}
        fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
        new_uuid = super(User,fields)
        
        #TODO: put this in the model instead
        unless options[:primary_account_id] == nil
          new_user = User[new_uuid]
          prim_acc = Account[options[:primary_account_id]]
          new_user.add_account(prim_acc)
          new_user.primary_account_id = prim_acc.uuid
          new_user.save
        end
        puts "uuid: #{new_uuid}"
        puts "login_id: #{fields[:login_id]}"
        puts "password: #{passwd}"
      end
    end

    desc "show [UUID] [options]", "Show one user or all users currently in the database"        
    def show(uuid = nil)
      if uuid        
        user = User[uuid] || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
User UUID:
  <%= user.canonical_uuid %>
Name:
  <%= user.name %>
<%- if user.login_id -%>
Login ID:
  <%= user.login_id %>
<%- end -%>
<%- if user.primary_account_id -%>
Primary Account:
<%- prim_acc = Account.find(:uuid => user.primary_account_id) -%>
  <%- if prim_acc.class == Account -%>
  <%= prim_acc.canonical_uuid %>\t<%= prim_acc.name %>
<%- else -%>
  <%= Account.uuid_prefix%>-<%= prim_acc.uuid %>\t<%= prim_acc.name %>
<%- end -%>
<%- end -%>
<%- unless user.accounts.empty? -%>
Associated accounts:
<%- user.accounts.each { |row| -%>
<%- if row.class == Account -%>
  <%= row.canonical_uuid %>\t<%= row.name %>
<%- else -%>
  <%= Account.uuid_prefix%>-<%= row.uuid %>\t<%= row.name %>
<%- end -%>
<%- } -%>
<%- end -%>
__END
      else
        user = User.all
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- user.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.name %>
<%- } -%>
__END
      end
    end    

    desc "modify UUID [options]", "Update an existing user."    
    method_option :name, :type => :string, :aliases => "-n", :desc => "The new name for the user." #Maximum size: 200    
    method_option :login_id, :type => :string, :aliases => "-l", :desc => "The new login_id for the user." #Maximum size: 255
    method_option :password, :type => :string, :aliases => "-p", :desc => "The new password for the user." #Maximum size: 255
    def modify(uuid)
      Error.raise("User name can not be longer than 200 characters",100) if options[:name] != nil && options[:name].length > 200
      Error.raise("User login_id can not be longer than 255 characters",100) if options[:login_id] != nil && options[:login_id].length > 255
      Error.raise("User password can not be longer than 255 characters",100) if options[:password] != nil && options[:password].length > 255
      Error.raise("User primary_account_id can not be longer than 255 characters",100) if options[:primary_account_id] != nil && options[:primary_account_id].length > 255
      
      fields = options.merge({})
      fields[:password] = User.encrypt_password(options[:password])
      fields[:primary_account_id] = Account.trim_uuid(options[:primary_account_id]) unless options[:primary_account_id].nil?
      
      super(User,uuid,fields)
    end

    #TODO: allow deletion of multiple id's at once
    desc "del UUID", "Delete an existing user."    
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def del(uuid)
      super(User,uuid)
      puts "User #{uuid} has been deleted." if options[:verbose]
    end
    
    desc "primacc UUID", "Set or get the primary account for a user"
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The id of the new primary account"
    def primacc(uuid)
      user = User[uuid] || UnknownUUIDError.raise(uuid)
      
      if options[:account_id]
        acc = Account[options[:account_id]] || UnknownUUIDError.raise(options[:account_id])
        user.primary_account_id = acc.uuid
        user.save
        user.add_account(acc) unless user.accounts.member?(acc)
      else
        puts Account.uuid_prefix + "-" + user.primary_account_id
      end
    end
    
    desc "associate UUID", "Associate a user with one or multiple accounts."
    method_option :account_ids, :type => :array, :required => true, :aliases => "-a", :desc => "The id of the acounts to associate these user with. Any non-existing or non numeral id will be ignored" 
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def associate(uuid)      
      user = User[uuid] || UnknownUUIDError.raise(uuid)
      options[:account_ids].each { |a|
        if Account[a].nil?
          puts "Unknown Account UUID: #{a}" if options[:verbose]
        elsif !user.accounts.index(Account[a]).nil?
          puts "User #{uuid} is already associated with account #{a}." if options[:verbose]
        else
          user.add_account(Account[a])
          if user.primary_account_id.nil?
            user.primary_account_id = Account.trim_uuid(a)
            user.save
          end
          puts "User #{uuid} successfully associated with account #{a}." if options[:verbose]
        end
      }
    end
    
    desc "dissociate UUID", "Dissociate a user from one or multiple accounts."    
    method_option :account_ids, :type => :array, :required => true, :aliases => "-a", :desc => "The id of the acounts to dissociate these user from. Any non-existing or non numeral id will be ignored" 
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def dissociate(uuid)
      user = User[uuid] || UnknownUUIDError.raise(uuid)
      options[:account_ids].each { |a|
        if Account[a].nil?
          puts "Unknown Account UUID: #{a}" if options[:verbose]
        elsif user.accounts.index(Account[a]).nil?
          puts "User #{uuid} is not associated with account #{a}." if options[:verbose]
        else
          user.remove_account(Account[a])
          
          puts "User #{uuid} successfully dissociated from account #{a}." if options[:verbose]
          
          if Account[a].uuid == user.primary_account_id
            user.primary_account_id = nil
            user.save
            puts "This was user #{uuid}'s primary account. Has been set to Null now." if options[:verbose]
          end
        end
      }
    end
    
  end
end
