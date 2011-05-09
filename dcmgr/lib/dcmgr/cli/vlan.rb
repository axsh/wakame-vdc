# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Vlan < Base
    namespace :vlan
    M = Dcmgr::Models

    desc "add [options]", "Create a new vlan lease."
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new vlan lease."
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account for this vlan lease."
    method_option :tag_id, :type => :string, :aliases => "-t", :desc => "The ethernet tag for this vlan lease"
    def add
      UnknownUUIDError.raise if M::Account[options[:account_id]].nil?
      Error.raise("Tag_id must be numeric",100) unless options[:tag_id].is_numeric?
      Error.raise("Tag_id already exists") unless M::VlanLease.find(:tag_id => options[:tag_id]).empty?
      
      super(M::VlanLease,options)
    end
  end
end
