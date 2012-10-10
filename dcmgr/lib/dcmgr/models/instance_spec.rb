# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceSpec < AccountResource
    taggable 'is'

    # serialization plugin must be defined at the bottom of all class
    # method calls.
    plugin :serialization
    serialize_attributes :yaml, :config
    # initial attached virtual interface definition:
    # {
    #   'vif1' => {
    #     :index => 0,     # (>=0) required and unique
    #     :bandwidth=>512, # (kbps) required
    #   },
    #   'vif2' => {
    #     :index => 10,    # (>=0) required and unique
    #     :bandwidth=>50000, # (kbps) required
    #   },
    # }
    serialize_attributes :yaml, :vifs
    # initial attached disk definition:
    # {
    #  # blank disk image file on host OS for swap device.
    #  'swap1' => {
    #    :index => 0,      # (>=0) required and unique
    #    :type  => :local, # required
    #    :size  => 100,    # (MB) required
    #  },
    #  # attach volume disk from snapshot.
    #  'volume1' => {
    #    :index => 1,      # (>=0) required and unique
    #    :type => :volume, # required
    #    :snapshot_id => 'snap-xxxxxx', # required
    #  },
    #  # attach blank volume disk.
    #  'volume2' => {
    #    :index => 5,      # (>=0) required and unique
    #    :type => :volume, # required
    #    :size => 100,     # (MB) required
    #  },
    # }
    serialize_attributes :yaml, :drives

    def before_validation
      default_config = {}

      self.config = default_config.merge(self.config || {})

      # Set empty hash for
      self.vifs ||= {}
      self.drives ||= {}
      super
    end

    def validate
      super

      # uniquness check for :index
      unless self.vifs.values.map {|i| i[:index] }.uniq.size == self.vifs.size
        errors.add(:vifs, "duplicate index value.")
      end
      unless self.drives.values.map {|i| i[:index] }.uniq.size == self.drives.size
        errors.add(:drives, "duplicate index value.")
      end
    end

    def to_api_document
      doc = super()
      doc.delete(:config)
      doc
    end

    # Modify methods for vifs,drives hash parameters.
    def add_vif(name, index, bandwidth)
      raise "Duplicate interface name: #{name}" if self.vifs.has_key?(name)
      self.vifs[name]={
        :index => index,
        :bandwidth => bandwidth,
      }
      self.changed_columns << :vifs
      self
    end

    def update_vif_index(name, new_index)
      raise "Unknown interface name: #{name}" if !self.vifs.has_key?(name)
      self.vifs[name][:index]=new_index
      self.changed_columns << :vifs
      self
    end

    def update_vif_bandwidth(name, bandwidth)
      raise "Unknown interface name: #{name}" if !self.vifs.has_key?(name)
      self.vifs[name][:bandwidth]=bandwidth
      self.changed_columns << :vifs
      self
    end

    def remove_vif(name)
      self.vifs.delete(name)
      self.changed_columns << :vifs
      self
    end

    def add_local_drive(name, index, size)
      raise "Duplicate drive name: #{name}" if self.drives.has_key?(name)
      self.drives[name] = {
        :index => index,
        :type => :local,
        :size => size,
      }
      self.changed_columns << :drives
      self
    end

    def add_volume_drive(name, index, size)
      raise "Duplicate drive name: #{name}" if self.drives.has_key?(name)
      self.drives[name] = {
        :index => index,
        :type => :volume,
        :size => size,
      }
      self.changed_columns << :drives
      self
    end

    def add_volume_drive_from_snapshot(name, index, snapshot_id)
      raise "Duplicate drive name: #{name}" if self.drives.has_key?(name)
      self.drives[name] = {
        :index => index,
        :type => :volume,
        :snapshot_id => snapshot_id,
      }
      self.changed_columns << :drives
      self
    end

    def update_drive_index(name, new_index)
      raise "Unknown drive name: #{name}" if !self.drives.has_key?(name)
      drive = self.drives[name]
      drive[:index] = new_index
      self.changed_columns << :drives
      self
    end

    def update_drive_snapshot_id(name, snapshot_id)
      raise "Unknown drive name: #{name}" if !self.drives.has_key?(name)
      drive = self.drives[name]
      raise "Snapshot ID can only be set to volume drive" if !(drive[:type] == :volume)
      drive.delete(:size)
      # TODO: syntax check for snapshot_id
      drive[:snapshot_id] = snapshot_id
      self.changed_columns << :drives
      self
    end

    def update_drive_size(name, size)
      raise "Unknown drive name: #{name}" if !self.drives.has_key?(name)
      drive = self.drives[name]
      drive.delete(:snapshot_id) if drive[:type] == :volume
      drive[:size] = size
      self.changed_columns << :drives
      self
    end

    def remove_drive(name)
      self.drives.delete(name)
      self.changed_columns << :drives
      self
    end

  end
end
