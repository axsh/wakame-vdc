# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class IpHandle < BaseNew
    include Dcmgr::Logger
    taggable 'ip'

    one_to_one :ip_lease, :class=>NetworkVifIpLease
    many_to_one :ip_pool

    subset(:alives, {:deleted_at => nil})

    def can_destroy
      self.ip_lease.nil? || self.ip_lease.network_vif.nil?
    end

    #
    # Sequel methods:
    #

    def validate
      errors.add(:ip_pool, "IP pool is not associated: #{self.canonical_uuid}") unless self.ip_pool
      # errors.add(:ip_lease, "IP lease is not associated: #{self.canonical_uuid}") unless self.ip_lease
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
