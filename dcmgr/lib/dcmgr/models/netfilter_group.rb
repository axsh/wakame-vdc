# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NetfilterGroup < AccountResource
    taggable 'nfgrp'
    with_timestamps

    inheritable_schema do
      String :name, :null=>false
      String :description
    end

    one_to_many :netfilter_rule

    def to_hash_document
      h = self.values.dup
      h[:id] = h[:uuid] = self.canonical_uuid
      h
    end

    def self.create_group(account_id, params)
      self.create(:account_id  => account_id,
                  :name        => params[:name],
                  :description => params[:description])
    end
  end
end
