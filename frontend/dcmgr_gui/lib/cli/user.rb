# -*- coding: utf-8 -*-

require 'tzinfo'

#TODO: Print only the first line of an exception?
module Cli
  class UserCli < Base
    namespace :user

    PASSWD_TABLE='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('').freeze

    desc "add [options]", "Create a new user."
    method_option :name, :type => :string, :required => true, :aliases => "-n", :desc => "The display name for the new user." #Maximum size: 200
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new user."
    method_option :login_id, :type => :string, :required=>true, :aliases => "-l", :desc => "The login_id for the new user." #Maximum size: 255
    method_option :password, :type => :string, :aliases => "-p", :desc => "The password for the new user." #Maximum size: 255
    method_option :primary_account_id, :type => :string, :aliases => "-a", :desc => "Optional: The primary account to associate this user with." #Maximum size: 255
    method_option :locale, :type => :string, :default=>"en", :desc => "The preffered display language for GUI."
    method_option :time_zone, :type => :string, :default=>::DEFAULT_TIMEZONE, :desc => "The display timezone for GUI."
    method_option :description, :type => :string, :desc => "Description field."
    def add
      if options[:name].length > 200
        Error.raise("User name can not be longer than 200 characters", 100)
      elsif options[:login_id].length > 255
        Error.raise("User login_id can not be longer than 255 characters",100)
      elsif options[:password] != nil && options[:password].length > 255
        Error.raise("User password can not be longer than 255 characters", 100)
      elsif options[:primary_account_id] != nil && options[:primary_account_id].length > 255
        Error.raise(Thor::Error, "User primary_account_id can not be longer than 255 characters",100)
      else
        #Check if the primary account uuid exists
        Error.raise("Unknown Account UUID #{options[:primary_account_id]}",100) if options[:primary_account_id] != nil && Account[options[:primary_account_id]].nil?

        #Generate password if password is null.
        passwd = options[:password] || Array.new(12) do PASSWD_TABLE[rand(PASSWD_TABLE.size)]; end.join

        #Encrypt the password
        pwd_hash = User.encrypt_password(passwd)

        #Put them in there
        fields = {:name => options[:name], :login_id => options[:login_id], :password => pwd_hash,
          :locale => options[:locale],
          :time_zone => options[:time_zone],
          :description => options[:description],
        }
        fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
        new_uuid = super(User,fields)

        #TODO: put this in the model instead
        unless options[:primary_account_id] == nil
          new_user = User[new_uuid]
          prim_acc = Account[options[:primary_account_id]]
          new_user.add_account(prim_acc)
          new_user.primary_account_id = prim_acc.canonical_uuid
          new_user.save
        end
        puts "uuid: #{new_uuid}"
        puts "login_id: #{fields[:login_id]}"
        puts "password: #{passwd}"
      end
    end

    desc "show [UUID] [options]", "Show one user or all users currently in the database"
    method_option :with_deleted, :type => :boolean, :aliases => "-d", :desc => "Show deleted users."
    def show(uuid = nil)
      if uuid
        ds = User.by_uuid(uuid)
        if options[:with_deleted]
          ds = ds.with_deleted
        end
        user = ds.first || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
User UUID: <%= user.canonical_uuid %>
Name: <%= user.name %>
Login ID: <%= user.login_id %>
Locale: <%= user.locale %>
Time Zone: <%= user.time_zone %>
Enabled: <%= user.enabled %>
Created: <%= user.created_at %>
Updated: <%= user.updated_at %>
<%- if user.deleted_at -%>
Deleted: <%= user.deleted_at %>
<%- end -%>
<%- if user.primary_account_id -%>
Primary Account: <%= user.primary_account_id %>
<%- end -%>
<%- if user.description -%>
Description:
<%= user.description %>
<%- end -%>
<%- unless user.accounts.empty? -%>
Associated accounts:
<%- user.accounts.each { |row| -%>
  <%= row.canonical_uuid %>\t<%= row.name %>
<%- } -%>
<%- end -%>
__END
      else
        ds = User.dataset
        if options[:with_deleted]
          ds = ds.with_deleted
        end
        table = [['UUID', 'Name', 'Login ID', 'Created', 'Enabled']]
        if options[:with_deleted]
          table[0] << 'Deleted'
        end
        ds.each {|u|
          row = [u.canonical_uuid, u.name, u.login_id, u.created_at.to_s, u.enabled.to_s]
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

    desc "modify UUID [options]", "Update an existing user."
    method_option :name, :type => :string, :aliases => "-n", :desc => "The display name for the user." #Maximum size: 200
    method_option :login_id, :type => :string, :aliases => "-l", :desc => "Login ID for the user." #Maximum size: 255
    method_option :password, :type => :string, :aliases => "-p", :desc => "Password for the user." #Maximum size: 255
    method_option :locale, :type => :string, :desc => "The preffered display language for GUI."
    method_option :time_zone, :type => :string, :desc => "The display timezone for GUI."
    method_option :description, :type => :string, :desc => "Description field."
    method_option :with_deleted, :type => :boolean, :aliases => "-d", :desc => "Modify deleted user."
    def modify(uuid)
      Error.raise("User name can not be longer than 200 characters",100) if options[:name] != nil && options[:name].length > 200
      Error.raise("User login_id can not be longer than 255 characters",100) if options[:login_id] != nil && options[:login_id].length > 255
      Error.raise("User password can not be longer than 255 characters",100) if options[:password] != nil && options[:password].length > 255

      fields = options.merge({})
      fields[:password] = User.encrypt_password(options[:password]) if options[:password]

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
        user.add_account(acc)
      end
    end

    desc "associate UUID", "Associate a user with one or multiple accounts."
    method_option :account_ids, :type => :array, :required => true, :aliases => "-a", :desc => "The id of the acounts to associate these user with. Any non-existing or non numeral id will be ignored"
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def associate(uuid)
      user = User[uuid] || UnknownUUIDError.raise(uuid)
      options[:account_ids].each { |a|
        acc = Account[a]
        if acc.nil?
          puts "Unknown Account UUID: #{a}" if options[:verbose]
        elsif !user.accounts_dataset.filter(:users_accounts__account_id=>acc.id).empty?
          puts "User #{uuid} is already associated with account #{a}." if options[:verbose]
        else
          user.add_account(acc)
          if user.primary_account_id.nil?
            user.primary_account_id = a
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
        acc = Account[a]
        if acc.nil?
          puts "Unknown Account UUID: #{a}" if options[:verbose]
        elsif user.accounts_dataset.filter(:users_accounts__account_id=>acc.id).empty?
          puts "User #{uuid} is not associated with account #{a}." if options[:verbose]
        else
          user.remove_account(acc)

          puts "User #{uuid} successfully dissociated from account #{a}." if options[:verbose]

          if acc.canonical_uuid == user.primary_account_id
            user.primary_account_id = nil
            user.save
            puts "This was user #{uuid}'s primary account. Has been set to Null now." if options[:verbose]
          end
        end
      }
    end

    desc "enable UUID", "Enable the user."
    def enable(uuid)
      user = User[uuid] || UnknownUUIDError.raise(uuid)
      user.enabled = true
      user.save_changes
    end

    desc "enable UUID", "Disable the user."
    def disable(uuid)
      user = User[uuid] || UnknownUUIDError.raise(uuid)
      user.enabled = false
      user.save_changes
    end

  end
end
