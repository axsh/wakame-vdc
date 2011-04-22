# -*- coding: utf-8 -*-

require 'sequel'
require 'yaml'

#TODO: Make sure :desc is filled in for every option
module Dcmgr::Cli
  class AccountCli < Base
    namespace :account
    M=Dcmgr::Models
    EMPTY_RECORD="<NULL>"

    no_tasks {
      def before_task
        # Setup DB connections and load paths for dcmgr_gui
        root_dir = File.expand_path('../../../', __FILE__)
        
        #get the database details
        #TODO:get this path in a less hard-coded way?
        content = File.new(File.expand_path('../../frontend/dcmgr_gui/config/database.yml', root_dir)).read
        settings = YAML::load content
        
        #load the database variables
        #TODO: get environment from RAILS_ENV
        db_environment = 'development'
        db_adapter     = settings[db_environment]['adapter']
        db_host        = settings[db_environment]['host']
        db_name        = settings[db_environment]['database']
        db_user        = settings[db_environment]['user']
        db_pwd         = settings[db_environment]['password']
        
        #Connect to the database
        url = "#{db_adapter}://#{db_host}/#{db_name}?user=#{db_user}&password=#{db_pwd}"
        db = Sequel.connect(url)
        
        #load the cli environment
        $LOAD_PATH.unshift File.expand_path('../../frontend/dcmgr_gui/config', root_dir)
        $LOAD_PATH.unshift File.expand_path('../../frontend/dcmgr_gui/app/models', root_dir)
        #require 'account'
        require 'environment-cli'
        
        #Associate the models with their respective database
        Account.db = db
        User.db = db
      end
    }

    desc "create", "Create a new account."
    #method_option :uuid, :type => :string, :required => true, :aliases => "-u", :desc => "The uuid for the new user." #Size: 8
    method_option :name, :type => :string, :aliases => "-n", :desc => "The name for the new account." #Maximum size: 255
    method_option :description, :type => :string, :aliases => "-d", :desc => "The description for this account."
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def create
      #Check if the data we got is valid
      if options[:name] != nil && options[:name].length > 255
        raise "Account name can not be longer than 255 characters."
      end
      if options[:description] != nil && options[:description].length > 100
        raise "Account description can not be longer than 100 chracters."
      end
      
      #Prepare the values to insert
      time = Time.new()
      now  = Sequel.string_to_datetime "#{time.year}-#{time.month}-#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
      #uuid = Account.uuid(options[:uuid])
      name = options[:name]
      
      #Put them in the backend
      new_acc = Dcmgr::Models::Account.create(    
                                              :description => options[:description],
                                              :enabled     => Dcmgr::Models::Account::ENABLED
                                              )
      
      #This should never happen as long as the databases remain synchronized.
      begin
        raise "A uuid collision occurred. This means the account databases are not synchronized." if Account.find(:uuid=>new_acc.uuid) != nil
      rescue
        new_acc.delete
        raise 
      end
      
      #Put them in the frontend
      Account.create(
                     :uuid       => new_acc.uuid,
                     :created_at => now,
                     :updated_at => now,
                     :name       => name
                     )
      
      puts "New account created with id #{new_acc.uuid}"
    end
    
    desc "describe", "Show all accounts currently in the database"
    method_option :id, :type => :string, :aliases => "-i", :desc => "The uuid for the account to show."
    method_option :times, :type => :boolean, :aliases => "-t", :desc => "Print the times when the user was created and last updated."
    method_option :associations, :type => :boolean, :aliases => "-a", :desc => "Print the user uuid(s) that the account is associated with."
    def describe
      #Known issue: crashes on 0000-00-00 00:00:00 timestamp
      #TODO: print this out prettier but still easy to use grep on => USE ERB
      
      header = "uuid | name | description | enabled"
      header += " | created at | last updated at" if options[:times]
      header += " | associated users" if options[:associations]
      
      puts header
      
      if options[:id] == nil
        accounts = Account.filter(:is_deleted => false).all
      else
        accounts = Account.filter(:uuid => options[:id],:is_deleted => false).all
      end
      
      accounts.each { |u|
        #prepare empty values
        uuid = EMPTY_RECORD
        name = EMPTY_RECORD
        desc = EMPTY_RECORD

        #set values that aren't empty
        #id = u[:id]
        name = u.name unless u.name == nil
        uuid = u.uuid unless u.uuid == nil
        acc_back = Dcmgr::Models::Account.find(:uuid => uuid)
        desc = acc_back.description unless acc_back.description == nil
        enabled = u.enable
	
        #Print it all
        print "#{uuid} | #{name} | #{desc} | #{enabled}"
	
        if options[:times]
          print " | #{u.created_at}"
          print " | #{u.updated_at}"
        end
	
        if options[:associations]
          #TODO: manipulate this string a bit better
          associations = "" 
          #DB[:users_accounts].filter(:account_id => id).all {
          u.users.each { |a|
            associations += "#{a.uuid}"
            associations += ", "
	  }
          associations = associations[0,associations.length-2]
          associations = EMPTY_RECORD if associations == nil
          
          print " | #{associations}"
        end
	
        print "\n"
      }
    end
    
    desc "update", "Update an existing account."
    method_option :id, :type => :string, :required => true, :aliases => "-i", :desc => "The uuid of the account to be updated."
    method_option :name, :type => :string, :aliases => "-n", :desc => "The new name for the account." #Maximum size: 200
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The new uuid for the account." #Maximum size: 8	
    method_option :description, :type => :string, :aliases => "-d", :desc => "The new description for the account."
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def update  
      if options[:name] != nil && options[:name].length > 255
        raise "Account name can not be longer than 255 characters."
      elsif options[:description] != nil && options[:description].length > 100
        raise "Description can not be longer than 100 characters."
      else
        time = Time.new()
        now = Sequel.string_to_datetime "#{time.year}-#{time.month}-#{time.day} #{time.hour}:#{time.min}:#{time.sec}"			
        to_be_updated = Account.find(:uuid => options[:id])
        to_be_updated_back = Dcmgr::Models::Account.find(:uuid => options[:id])
        
        raise "An account with id #{options[:id]} doesn't exit" if to_be_updated == nil or to_be_updated.is_deleted
        
        #this variables will be set in case any change to an account is made. Used to determine if update_at needs to be set.
        changed = false
        
        unless options[:description] == nil
          to_be_updated_back.description = options[:description]
          changed = true
        end
        
        unless options[:uuid] == nil
          uuid = Account.uuid(options[:uuid])
          
          #Update all users that have this account as their default		    
          User.filter(:primary_account_id => to_be_updated.uuid).all.each { |prim_acc|
            prim_acc.primary_account_id = uuid
            prim_acc.updated_at = now
            prim_acc.save
            puts "Updated user #{prim_acc.uuid} that had this account has its primary account." if options[:verbose]
          }
          
          #Update the account
          to_be_updated.uuid = uuid
          to_be_updated_back.uuid = uuid
          puts "Account #{options[:id]}'s uuid changed to #{uuid}" if options[:verbose]
          changed = true
        end
        
        unless options[:name] == nil
          #to_be_updated.update(:name => options[:name]) 
          to_be_updated.name = options[:name]
          puts "Account #{options[:id]}'s name changed to #{options[:name]}" if options[:verbose]
          changed = true
        end
        
        if changed
          #to_be_updated.update(:updated_at => now)
          to_be_updated.updated_at = now
          to_be_updated_back.updated_at = now
          to_be_updated.save
          to_be_updated_back.save
        else
          puts "Nothing to do." if options[:verbose]
        end
      end
    end
    
    #TODO: show account to confirm deletion
    desc "delete", "Deletes an existing account."
    method_option :id, :type => :string, :required => true, :aliases => "-i", :desc => "The id of the account to be deleted."
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def delete				
      time = Time.new()
      now  = Sequel.string_to_datetime "#{time.year}-#{time.month}-#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
      id   = Account.uuid(options[:id])
      
      to_delete = Account.find(:uuid => id)
      raise "No account exists with that id" if to_delete == nil || to_delete.is_deleted

      to_delete.is_deleted = true
      to_delete.deleted_at = now
      
      to_delete_back = Dcmgr::Models::Account.find(:uuid => id)
      to_delete_back.delete
      
      puts "Account #{id} has been deleted." if options[:verbose]
      
      relations = to_delete.users
      for ss in 0...relations.length do
        puts "Deleting association with user #{relations[0].uuid}." if options[:verbose]
        to_delete.remove_user(relations[0])		  
      end
      
      to_delete.save
    end
    
    desc "enable", "Enable an account."
    method_option :id, :type => :string, :required => true, :aliases => "-i", :desc => "The id of the account to be enabled."
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def enable
      time = Time.new()
      now  = Sequel.string_to_datetime "#{time.year}-#{time.month}-#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
      id   = Account.uuid(options[:id])
      
      to_enable = Account.find(:uuid => id)
      raise "No account exists with that id" if to_enable == nil or to_enable.is_deleted
      
      if to_enable.enable
        puts "Account #{id} is already enabled." if options[:verbose]
      else      
        to_enable.enable = Account::ENABLED
        to_enable.updated_at = now
        to_enable.save
	
        to_enable_back = Dcmgr::Models::Account.find(:uuid => id)
        to_enable_back.enabled = Dcmgr::Models::Account::ENABLED
        to_enable_back.updated_at = now
        to_enable_back.save
	
        puts "Account #{id} has been enabled." if options[:verbose]
      end
    end
    
    desc "disable", "Disable an account."
    method_option :id, :type => :string, :required => true, :aliases => "-i", :desc => "The id of the account to be disabled."
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def disable
      time = Time.new()
      now  = Sequel.string_to_datetime "#{time.year}-#{time.month}-#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
      id   = Account.uuid(options[:id])
      
      to_disable = Account.find(:uuid => id)
      raise "No account exists with that id" if to_disable == nil or to_disable.is_deleted
      
      unless to_disable.enable
        puts "Account #{id} is already disabled." if options[:verbose]
      else
        to_disable.enable = Account::DISABLED
        to_disable.updated_at = now
        to_disable.save

        to_enable_back = Dcmgr::Models::Account.find(:uuid => id)
        to_enable_back.enabled = Dcmgr::Models::Account::DISABLED
        to_enable_back.updated_at = now
        to_enable_back.save
        
        puts "Account #{id} has been disabled." if options[:verbose]
      end
    end
    
    desc "associate", "Associate an account with a user or multiple users."
    method_option :users, :type => :array, :required => true, :aliases => "-u", :desc => "The id of the users to associate with the account. Any non-existing or non numeral id will be ignored"
    method_option :id, :type => :string, :required => true, :aliases => "-i", :desc => "The id of the acount to associate these users with." 
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def associate
      uid = options[:users]
      aid = Account.uuid(options[:id])
      
      account = Account.find(:uuid => aid)
      
      raise "An account with id #{aid} doesn't exist." if account == nil or account.is_deleted
      #raise "A user with id #{uid} doesn't exist." if User.filter(:id => uid).empty?
      
      uid.each { |u|
        #TODO: ccheck uuid syntax?
        #user_uuid = Account.uuid(u)
        #puts "#{u} is not a valid user id." if options[:verbose]
        if User.find(:uuid => u) == nil
          puts "A user with id #{u} doesn't exist."
        elsif account.users.index(User.find(:uuid => u)) != nil
          puts "Account #{aid} is already associated with user #{u}." if options[:verbose]
        else
          account.add_user(User.find(:uuid => u))
          
          puts "Account #{aid} successfully associated with user #{u}." if options[:verbose]
        end
      }
    end
    
    desc "dissociate", "Dissociate an account from a user or multiple users."
    method_option :users, :type => :array, :required => true, :aliases => "-u", :desc => "The id of the users to dissociate from the account. Any non-existing or non numeral id will be ignored"
    method_option :id, :type => :string, :required => true, :aliases => "-i", :desc => "The id of the acount to dissociate these users from." 
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "Print feedback on what is happening."
    def dissociate
      uid = options[:users]
      aid = Account.uuid(options[:id])
      
      account = Account.find(:uuid => aid)
      
      raise "An account with id #{aid} doesn't exist." if account == nil or account.is_deleted
      
      uid.each { |u|
        #TODO: check uuid syntax?
        #user_uuid = Account.uuid(u)        
        if User.find(:uuid => u) == nil
          puts "A user with id #{u} doesn't exist."
        elsif account.users.index(User.find(:uuid => u)) == nil
          puts "User #{u} is not associated with account #{aid}." if options[:verbose]
        else
          account.remove_user(User.find(:uuid => u))
          
          puts "Account #{aid} successfully dissociated from user #{u}." if options[:verbose]
          
          user = User.find(:uuid => uid)
          if account.uuid == user.primary_account_id
            user.primary_account_id = nil
            user.save
            puts "  This was user #{uid}'s primary account. Has been set to Null now." if options[:verbose]
          end
        end
      }
    end
    
  end
end
