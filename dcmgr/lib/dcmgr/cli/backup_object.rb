# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class BackupObject < Base
    namespace :backupobject
    M = Dcmgr::Models

    desc "add [options]", "Register a backup object"
    method_option :uuid, :type => :string, :desc => "The UUID for the backup storage."
    method_option :account_id, :type => :string, :default=>'a-shpoolxx', :desc => "The account ID for the backup object."
    method_option :display_name, :type => :string, :required=>true, :desc => "The display name for the backup object."
    method_option :storage_id, :type => :string, :required=>true, :desc => "The backup storage ID to store the backup object."
    method_option :object_key, :type => :string, :required=>true, :desc => "The object key of the backup object."
    method_option :state, :type => :string, :default=>:available, :desc => "The state of the backup object."
    method_option :size, :type => :numeric, :required=>true, :desc => "The original file size of the backup object."
    method_option :allocation_size, :type => :numeric, :desc => "The allcated file size of the backup object."
    method_option :checksum, :type => :string, :required=>true, :desc => "The checksum of the backup object."
    method_option :description, :type => :string, :desc => "Description of the backup storage"
    method_option :service_type, :type => :string, :default=>Dcmgr.conf.default_service_type, :desc => "Service type of the backup object. (#{Dcmgr.conf.service_types.keys.sort.join(', ')})"
    def add
      bkst = M::BackupStorage[options[:storage_id]] || UnknownUUIDError.raise("Backup Storage UUID: #{options[:storage_id]}")

      options[:allocation_size] ||= options[:size]
      
      fields = options.dup
      fields.delete(:storage_id)
      fields[:backup_storage_id] = bkst.id
      puts super(M::BackupObject, fields)
    end
    
    desc "modify UUID [options]", "Modify the backup object"
    method_option :uuid, :type => :string, :desc => "The UUID for the backup storage."
    method_option :account_id, :type => :string, :default=>'a-shpoolxx', :desc => "The account ID for the backup object."
    method_option :display_name, :type => :string, :desc => "The display name for the backup object."
    method_option :storage_id, :type => :string, :desc => "The backup storage ID to store the backup object."
    method_option :object_key, :type => :string, :desc => "The object key of the backup object."
    method_option :state, :type => :string, :desc => "The state of the backup object."
    method_option :size, :type => :numeric, :desc => "The original file size of the backup object."
    method_option :allocation_size, :type => :numeric, :desc => "The allcated file size of the backup object."
    method_option :checksum, :type => :string, :desc => "The checksum of the backup object."
    method_option :description, :type => :string, :desc => "Description of the backup storage"
    method_option :service_type, :type => :string, :desc => "Service type of the backup object. (#{Dcmgr.conf.service_types.keys.sort.join(', ')})"
    def modify(uuid)
      bo = M::BackupObject[uuid] || UnknownUUIDError.raise(uuid)
      fields = options.dup
      fields.delete(:storage_id)
      fields[:backup_storage_id] = bkst.id
      puts super(M::BackupObject, bo.canonical_uuid, fields)
    end

    desc "del UUID", "Deregister the backup object"
    def del(uuid)
      super(M::BackupObject,uuid)
    end

    
    desc "show [UUID]", "Show the backup object details"
    def show(uuid=nil)
      if uuid
        bo = M::BackupObject[uuid]
        puts ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= bo.canonical_uuid %>
Name: <%= bo.display_name %>
Account ID: <%= bo.account_id %>
Backup Storage UUID: <%= bo.backup_storage.canonical_uuid %>
Object Key: <%= bo.object_key %>
Size: <%= bo.size %> (Alloc Size: <%= bo.allocation_size %>)
Checksum: <%= bo.checksum %>
<%- if bo.description -%>
Description:
<%= bo.description %>
<%- end -%>
Create: <%= bo.created_at %>
Update: <%= bo.updated_at %>
Delete: <%= bo.deleted_at %>
__END
      else
        ds = M::BackupObject.dataset
        puts ERB.new(<<__END, nil, '-').result(binding)
<%= "%-15s %-15s %-20s %-20s %-10s" % ['UUID', 'Account ID', 'Name', 'Size', 'Checksum'] %>
<%- ds.each { |row| -%>
<%= "%-15s %-15s %-20s %-20s %-10s" % [row.canonical_uuid, row.account_id, row.display_name, row.size, row.checksum[0,10]] %>
<%- } -%>
__END
      end
    end
    
  end
end
