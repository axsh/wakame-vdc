# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Group < Base
    namespace :group
    M = Dcmgr::Models

    desc "add [options]", "Add a new security group."
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new security group."
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account this security group belongs to.", :required => true
    method_option :name, :type => :string, :aliases => "-n", :desc => "The name for this security group.", :required => true
    method_option :description, :type => :string, :aliases => "-d", :desc => "The description for this new security group."
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      
      puts super(M::NetfilterGroup,options)
    end
    
    desc "addrule UUID [options]", "Add a rule to a security group"
    method_option :rule, :type => :string, :aliases => "-r", :desc => "The new rule to be added."
    def addrule(g_uuid)
      UnknownUUIDError.raise(g_uuid) if M::NetfilterGroup[g_uuid].nil?
      
      #TODO: check rule syntax
      new_rule = M::NetfilterRule.new(:permission => options[:rule])
      new_rule.netfilter_group = M::NetfilterGroup[g_uuid]
      new_rule.save
    end
    
    desc "delrule UUID [options]", "Delete a rule from a security group"
    method_option :rule, :type => :string, :aliases => "-r", :desc => "The rule to be deleted."
    def delrule(g_uuid)
      UnknownUUIDError.raise(g_uuid) if M::NetfilterGroup[g_uuid].nil?
      rule = M::NetfilterRule.find(:netfilter_group_id => M::NetfilterGroup[g_uuid].id,:permission => options[:rule])
      Error.raise("Group '#{g_uuid}' does not contain rule '#{options[:rule]}'.",100) if rule.nil?
      
      rule.destroy
    end
  end
end
