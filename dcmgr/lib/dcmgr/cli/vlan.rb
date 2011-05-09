# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Vlan < Base
    namespace :vlan
    M = Dcmgr::Models

    desc "add [options]", "Create a new vlan lease."
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new vlan lease."
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account for this vlan lease."
    method_option :tag_id, :type => :numeric, :aliases => "-t", :desc => "The ethernet tag for this vlan lease"
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      Error.raise("Tag_id already exists",100) unless M::VlanLease.find(:tag_id => options[:tag_id]).nil?
      
      super(M::VlanLease,options)
    end
  end
end
