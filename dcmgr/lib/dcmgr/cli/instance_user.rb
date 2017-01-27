# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class InstanceUser < Base
    namespace :instanceuser
    M = Dcmgr::Models

    desc "add [options]", "Register a new user."
    method_option :uuid, :type => :string, :desc => "The UUID for the new user"
    method_option :instance_id, :type => :string, :desc => "The UUID of the instance this user belongs to", :required => true
    method_option :username, :type => :string, :desc => "user name", :required => true
    method_option :encrypted_password, :type => :string, :desc => "public rsa pem encryped password", :required => true

    def add
      UnknownUUIDError.raise(options[:instance_id]) if M::Instance[options[:instance_id]].nil?
      
      fields = options.dup
      
      puts super(M::InstanceUser,fields)
    end
    
    desc "modify UUID [options]", "Modify an existing user."
    method_option :instance_id, :type => :string, :desc => "The UUID of the account this key pair belongs to"
    method_option :username, :type => :string, :desc => "user name"
    method_option :encrypted_password, :type => :string, :desc => "public rsa pem encryped password"
    def modify(uuid)
      UnknownUUIDError.raise(options[:instance_id]) if options[:instance_id] && M::Instance[options[:instance_id]].nil?
      super(M::InstanceUser,uuid,options)
    end
    
    desc "del UUID", "Delete an existing user"
    def del(uuid)
      super(M::InstanceUser,uuid)
    end
    
    desc "show [UUID] [options]", "Show user(s)"
    def show(uuid=nil)
      if uuid
        iuser = M::InstanceUser[uuid] || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
Instance User UUID: <%= iuser.canonical_uuid %>
Instance id: <%= iuser.instance_id %>
username: <%= iuser.username %>
Encrypted Password: <%= iuser.encrypted_password %>
__END
      else
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- M::InstanceUser.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.instance_id %>\t<%= row.username %>
<%- } -%>
__END
      end
    end
    
  end
end
