# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class IpPool < AccountResource
    include Dcmgr::Logger
    taggable 'ipp'

    many_to_many :dc_networks, :join_table=>:ip_pool_dc_networks
    one_to_many :ip_handles do |ds|
      ds.alives
    end

    subset(:alives, {:deleted_at => nil})

    def has_dc_network(dcn)
      !dc_networks_dataset.where(:dc_networks__id => dcn.id).empty?
    end

    #
    # Sequel methods:
    #

    def validate
      # Validate expire values. Limit to reasonable length of time to avoid integer overflow.
      super
    end

    def before_destroy
      self.ip_handles_dataset.destroy

      super
    end

  end

end
