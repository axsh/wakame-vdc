# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class IpHandle < BaseNew
    include Dcmgr::Logger
    taggable 'ip'

    one_to_one :ip_lease, :class=>NetworkVifIpLease
    many_to_one :ip_pool

    subset(:alives, {:ip_handles__deleted_at => nil})
    # Doesn't properly take into account if the ip lease is associated with a vif.
    subset(:expiring) {expires_at != nil && deleted_at == nil}

    subset(:expired) {expires_at <= Time.now}

    dataset_module {
      def join_with_ip_leases
        self.join_table(:left, :network_vif_ip_leases, :network_vif_ip_leases__ip_handle_id => :ip_handles__id)
      end

      def where_with_ip_leases(param)
        self.join_with_ip_leases.where(param).select_all(:ip_handles)
      end

      def exclude_with_ip_leases(param)
        self.join_with_ip_leases.exclude(param).select_all(:ip_handles)
      end

      def leased
        self.exclude_with_ip_leases(:network_vif_ip_leases__network_vif_id => nil)
      end

      def not_leased
        self.where_with_ip_leases(:network_vif_ip_leases__network_vif_id => nil)
      end
    }

    def can_destroy
      self.ip_lease.nil? || self.ip_lease.network_vif.nil?
    end

    def should_expire_now
      self.expires_at && self.delete_at.nil? && self.expires_at <= Time.now
    end

    #
    # Sequel methods:
    #

    def validate
      errors.add(:ip_pool, "IP pool is not associated: #{self.canonical_uuid}") unless self.ip_pool
      # errors.add(:ip_lease, "IP lease is not associated: #{self.canonical_uuid}") unless self.ip_lease
      super
    end

    def before_save
      if new?
        self.expires_at = Time.now + self.ip_pool.expire_initial if self.ip_pool.expire_initial
      end

      if self.ip_lease && self.ip_lease.network_vif
        self.expires_at = nil
      end

      super
    end

    def before_destroy
      raise "Cannot destroy an IP handle that is still leased by a Network Vif." unless self.can_destroy
      self.ip_lease.destroy unless self.ip_lease.nil?
      super
    end

    # override Sequel::Model#delete not to delete rows but to set
    # delete flags.
    def delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

  end

end
