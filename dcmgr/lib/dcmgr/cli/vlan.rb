# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Vlan < Base
    namespace :vlan
    M = Dcmgr::Models

    desc "add [options]", "Create a new vlan lease"
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new vlan lease"
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account for this vlan lease"
    method_option :tag_id, :type => :numeric, :aliases => "-t", :desc => "The ethernet tag for this vlan lease"
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      Error.raise("Tag_id already exists",100) unless M::VlanLease.find(:tag_id => options[:tag_id]).nil?
      
      puts super(M::VlanLease,options)
    end
    
    desc "del UUID", "Delete an existing vlan lease"
    def del(uuid)
      super(M::VlanLease,uuid)
    end
    
    desc "modify UUID [options]", "Modify an existing vlan lease"
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account for this vlan lease"
    method_option :tag_id, :type => :numeric, :aliases => "-t", :desc => "The ethernet tag for this vlan lease"
    def modify(uuid)
      UnknownUUIDError.raise(options[:account_id]) if options[:account_id] && M::Account[options[:account_id]].nil?
      super(M::VlanLease,uuid,options)
    end
    
    desc "show [UUID]", "Show existing vlan lease(s)"
    def show(uuid=nil)
      if uuid
        lease = M::VlanLease[uuid] || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
Vlan Lease UUID: <%= lease.canonical_uuid %>
Account id: <%= lease.account_id %>
Tag id: <%= lease.tag_id %>
__END
      else
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- M::VlanLease.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.account_id %>\t<%= row.tag_id %>
<%- } -%>
__END
      end
    end
  end
end
