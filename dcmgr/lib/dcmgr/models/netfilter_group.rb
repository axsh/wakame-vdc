# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetfilterGroup < AccountResource
    taggable 'ng'

    one_to_many :netfilter_rules
    many_to_many :instances,:join_table => :instance_netfilter_groups

    def to_hash
      super.merge({
                    :rule => rule.to_s,
                    :rules => netfilter_rules.map { |rule| rule.to_hash },
                  })
    end

    def to_api_document
      super.merge({
                    :rule => rule.to_s,
                    :rules => netfilter_rules.map { |rule| rule.to_hash },
                  })
    end
    
    def after_save
      super
      self.rebuild_rule
    end

    def flush_rule
      NetfilterRule.filter(:netfilter_group_id => self.id).destroy
    end

    def before_destroy
      return false if self.instances.size > 0

      self.flush_rule
      super
    end
    alias :destroy_group :destroy

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

  end
end
