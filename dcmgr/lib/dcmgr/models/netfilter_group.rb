# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetfilterGroup < AccountResource
    taggable 'nfgrp'
    with_timestamps

    inheritable_schema do
      String :name, :null=>false
      String :description
      String :rule
    end

    one_to_many :netfilter_rules

    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = self.canonical_uuid
      h
    end

    def self.create_group(account_id, params)
      grp = self.create(:account_id  => account_id,
                        :name        => params[:name],
                        :description => params[:description],
                        :rule        => params[:rule])
      grp.build_rule
      grp
    end

    def destroy_rule
      #p self.netfilter_rules
      NetfilterRule.filter(:netfilter_group_id => self.id).destroy
    end

    def destroy_group
      self.destroy_rule
      self.destroy
    end

    def rebuild_rule
      self.destroy_rule
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
