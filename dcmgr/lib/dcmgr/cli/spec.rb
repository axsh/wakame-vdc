# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Spec < Base
    namespace :spec
    M = Dcmgr::Models

    desc "add [options]", "Create a new set of instance specifications."
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new instance specifications."
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account for the new instance specifications.", :required => true
    method_option :arch, :type => :string, :desc => "The architecture for the new instance specifications.", :required => true
    method_option :cpu_cores, :type => :numeric, :aliases => "-cc", :desc => "The number of cpu cores for the new instance specifications.", :required => true
    method_option :quota_weight, :type => :numeric, :aliases => "-q", :desc => "The quota weight for the new instance specifications.", :required => true
    method_option :config, :type => :string, :aliases => "-co", :desc => "The configuration for the new instance specifications."
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      UnsupportedArchError.raise(options[:arch]) unless HostPool::SUPPORTED_ARCH.member?(options[:arch])
      
      puts super(M::InstanceSpec,options.merge({:hypervisor => M::HostPool::HYPERVISOR_KVM}))
    end
  end
end
