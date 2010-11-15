# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network interface for running instance.
  class InstanceNic < BaseNew
    taggable 'nic'

    inheritable_schema do
      Fixnum :instance_id, :null=>false
      String :vif, :null=>false, :size=>50
      String :mac_addr, :null=>false, :size=>12
      
      index :mac_addr, {:unique=>true}
    end
    with_timestamps

    many_to_one :instance
    one_to_one :ip, :class=>IpLease

    def to_hash
      h = values.dup.merge(super)
      h.delete(:instance_id)
      h
    end

    def before_validation
      super
      m = normalize_mac_addr(self[:mac_addr])
      if m.size == 6
        # mac_addr looks like to only have vendor ID part so that
        # generate unique value for node ID part.
        mvendor = m
        begin
          m = mvendor + ("%02x%02x%02x" % [rand(0xff),rand(0xff),rand(0xff)])
        end while self.class.find(:mac_addr=> m)
        self[:mac_addr] = m
      end
      true
    end

    def validate
      super

      unless self.mac_addr.size == 12
        errors.add(:mac_addr, "Invalid mac address length: #{self.mac_addr}")
      end

      unless self.mac_addr =~ /^[0-9a-f]{12}$/
        errors.add(:mac_addr, "Invalid mac address syntax: #{self.mac_addr}")
      end
    end

    def pretty_mac_addr(delim=':')
      self.mac_addr.unpack('A2'*6).join(delim)
    end

    private
    def normalize_mac_addr(str)
      str = str.downcase.gsub(/[^0-9a-f]/, '')
      raise "invalid mac address data: #{str}" if str.size > 12
      # TODO: put more checks on the mac address.
      #       i.e. single 0 to double 00
      str
    end
    
    
  end
end
