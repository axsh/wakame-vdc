# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class BackupObject < Base
    namespace :backupobject
    M = Dcmgr::Models

    desc "add [options]", "Register a backup object"
    method_option :uuid, :type => :string, :desc => "The UUID for the backup storage."
    method_option :storage_id, :type => :string, :required=>true, :desc => "The  to store the backup object."
    method_option :object_key, :type => :string, :required=>true, :desc => "The object key of the backup object."
    method_option :state, :type => :string, :default=>:available, :desc => "The state of the backup object."
    method_option :size, :type => :numeric, :required=>true, :desc => "The file size of the backup object."
    method_option :checksum, :type => :string, :required=>true, :desc => "The checksum of the backup object."
    method_option :description, :type => :string, :desc => "Description of the backup storage"
    method_option :service_type, :type => :string, :default=>Dcmgr.conf.default_service_type, :desc => "Service type of the backup object. (#{Dcmgr.conf.service_types.keys.sort.join(', ')})"
    def add
      bkst = M::BackupStorage[options[:storage_id]] || UnknownUUIDError.raise("Backup Storage UUID: #{options[:storage_id]}")
      
      fields = {
        :uuid => options[:uuid],
        :backup_storage_id => bkst.id,
        :state => options[:state],
        :size => options[:size],
        :object_key => options[:object_key],
        :checksum => options[:checksum],
        :description => options[:description],
      }
      puts super(M::BackupObject, fields)
    end
    
    desc "modify UUID [options]", "Modify the backup object"
    method_option :uuid, :type => :string, :desc => "The UUID for the backup storage."
    method_option :storage_id, :type => :string, :desc => "The  to store the backup object."
    method_option :object_key, :type => :string, :desc => "The object key of the backup object."
    method_option :state, :type => :string, :default=>:available, :desc => "The state of the backup object."
    method_option :size, :type => :numeric, :desc => "The file size of the backup object."
    method_option :checksum, :type => :string, :desc => "The checksum of the backup object."
    method_option :description, :type => :string, :desc => "Description of the backup storage"
    method_option :service_type, :type => :string, :default=>Dcmgr.conf.default_service_type, :desc => "Service type of the backup object. (#{Dcmgr.conf.service_types.keys.sort.join(', ')})"
    def modify(uuid)
      bo = M::BackupObject[uuid] || UnknownUUIDError.raise(uuid)
      fields = {
        :uuid=>options[:uuid],
        :backup_storage_id => bkst.id,
        :state => options[:state],
        :size => options[:size],
        :object_key => options[:object_key],
        :checksum => options[:checksum],
        :description => options[:description],
      }
      puts super(M::BackupObject, bo.canonical_uuid, fields)
    end

    desc "del UUID", "Deregister the backup object"
    def del(uuid)
      super(M::BackupObject,uuid)
    end

    
    desc "show [UUID]", "Show the backup object details"
    def show(uuid=nil)
      if uuid
        bk = M::BackupStorage[uuid]
        puts ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= bk.canonical_uuid %>
Backup Storage UUID: <%= bk.backup_storage.canonical_uuid %>
Object Key: <%= bk.object_key %>
Checksum: <%= bk.checksum %>
<%- if bk.description -%>
Description:
<%= bk.description %>
<%- end -%>
Create: <%= bk.created_at %>
Update: <%= bk.updated_at %>
Delete: <%= bk.deleted_at %>
__END
      else
        ds = M::BackupObject.dataset
        puts ERB.new(<<__END, nil, '-').result(binding)
<%= "%-15s %-20s %-20s" % ['UUID', 'Storage Type', 'Base URI'] %>
<%- ds.each { |row| -%>
<%= "%-15s %-20s %-20s" % [row.canonical_uuid, row.storage_type, row.base_uri] %>
<%- } -%>
__END
      end
    end
    
  end
end
