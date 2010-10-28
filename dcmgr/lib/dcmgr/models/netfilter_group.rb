# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetfilterGroup < AccountResource
    taggable 'ng'
    with_timestamps

    inheritable_schema do
      String :name, :null=>false
      String :description
      Text   :rule
    end

    one_to_many :netfilter_rules
    one_to_many :instance_netfilter_groups

    def to_hash
      {
        :name => name,
        :description => description,
        :rules => netfilter_rules.map { |rule| rule.to_hash },
      }
    end

    def self.create_group(account_id, params)
      grp = self.create(:account_id  => account_id,
                        :name        => params[:name],
                        :description => params[:description])
      grp.build_rule
      grp
    end

    def flush_rule
      NetfilterRule.filter(:netfilter_group_id => self.id).destroy
    end

    def destroy_group
      self.flush_rule
      self.destroy
    end

    def rebuild_rule
      self.flush_rule
      self.build_rule
    end

    def build_rule
      return if self.rule.nil?

      self.rule.split("\n").each { |permission|
        # [ToDo]
        # to make strong parser
        next if permission =~ /\A#/
        next if permission.length == 0

        # [format] protocol,source,destination
        # - protocol: tcp|udp|icmp
        # - source: IPAddr|CIDR|Owner:Group
        # - destination: port|icmp-type
        NetfilterRule.create(:netfilter_group_id => self.id,
                             :permission         => permission)

      }
    end

    def instances
      self.instance_netfilter_groups.map { |instance_netfilter_group|
        instance_netfilter_group.instance
      }
    end

  end
end
