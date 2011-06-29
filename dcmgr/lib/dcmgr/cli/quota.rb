# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Quota < Base
    namespace :quota
    M = Dcmgr::Models
  
    desc "modify ACCOUNT_UUID [options]", "Modify the quota settings for an account"
    method_option :weight, :type => :numeric, :aliases => "-w", :desc => "The instance total weight for this account's quota"
    method_option :size, :type => :numeric, :aliases => "-s", :desc => "The volume total size for this account's quota"
    def modify(account_uuid)
      acc = M::Account[account_uuid] || UnknownUUIDError.raise(account_uuid)
      super(M::Quota,acc.quota.canonical_uuid,{:instance_total_weight => options[:weight], :volume_total_size => options[:size]})
    end
    
    desc "show ACCOUNT_UUID", "Show the quota settings for an account"
    def show(account_uuid)
      acc = M::Account[account_uuid] || raise(Thor::Error, "Unknown Account UUID: #{account_uuid}")
      puts ERB.new(<<__END, nil, '-').result(binding)
Instance total weight:
  <%= acc.quota.instance_total_weight %>
Volume total size:
  <%= acc.quota.volume_total_size %>
__END
    end
    
  end
end
