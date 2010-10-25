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

    def self.create_group(account_id, params)
      grp = self.create(:account_id  => account_id,
                        :name        => params[:name],
                        :description => params[:description],
                        :rule        => params[:rule])
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

  end
end
