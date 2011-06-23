# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetfilterGroup < AccountResource
    taggable 'ng'
    with_timestamps

    inheritable_schema do
      String :name, :null=>false
      String :description
      Text   :rule
      index [:account_id, :name], {:unique=>true}
    end

    one_to_many :netfilter_rules
    many_to_many :instances,:join_table => :instance_netfilter_groups

    def to_hash
      h = super
      h = h.merge({
                    :rule => rule.to_s,
                    :rules => netfilter_rules.map { |rule| rule.to_hash },
                  })
      #{
      #:id => self.canonical_uuid,
      #:name => name,
      #:description => description,
      #:rules => netfilter_rules.map { |rule| rule.to_hash },
      #}
    end
    
    def to_api_document
      to_hash
    end

    def to_tiny_hash
      {
        :name => self.name,
        :uuid => self.canonical_uuid,
      }
    end

    def self.create_group(account_id, params)
      grp = self.create(:account_id  => account_id,
                        :name        => params[:name],
                        :rule        => params[:rule],
                        :description => params[:description])
      grp.build_rule
      grp
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
