# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class BackupStorage < Base
    namespace :backupstorage
    M = Dcmgr::Models

    desc "add [options]", "Register a backup storage"
    method_option :uuid, :type => :string, :desc => "The UUID for the backup storage."
    method_option :display_name, :type => :string, :required=>true, :desc => "The display name for the backup storage."
    method_option :base_uri, :type => :string, :required=>true, :desc => "The base URI to store the backup objects."
    method_option :storage_type, :type => :string, :required=>true, :desc => "Storage driver name of the backup storage: #{M::BackupStorage::STORAGE_TYPES.join(', ')}"
    method_option :description, :type => :string, :desc => "Description of the backup storage"
    def add()
      Error.raise(options[:storage_type]) unless M::BackupStorage::STORAGE_TYPES.member?(options[:storage_type].to_sym)
      fields = options.dup
      puts super(M::BackupStorage, fields)
    end

    desc "modify UUID [options]", "Modify the backup storage"
    method_option :uuid, :type => :string, :desc => "The UUID for the backup storage."
    method_option :display_name, :type => :string, :desc => "The display name for the backup storage."
    method_option :base_uri, :type => :string, :desc => "The base URI to store the backup objects."
    method_option :storage_type, :type => :string, :desc => "Storage driver name of the backup storage: #{M::BackupStorage::STORAGE_TYPES.join(', ')}"
    method_option :description, :type => :string, :desc => "Description of the backup storage"
    def modify(uuid)
      bkst = M::BackupStorage[uuid] || UnknownUUIDError.raise(uuid)
      fields = options.dup
      puts super(M::BackupStorage, bkst.canonical_uuid, fields)
    end

    desc "del UUID", "Deregister the backup storage"
    def del(uuid)
      super(M::BackupStorage,uuid)
    end

    desc "show [UUID]", "Show the backup storage details"
    def show(uuid=nil)
      if uuid
        bkst = M::BackupStorage[uuid]
        puts ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= bkst.canonical_uuid %>
Name: <%= bkst.display_name %>
Storage Type: <%= bkst.storage_type %>
Base URI: <%= bkst.base_uri %>
<%- if bkst.description -%>
Description:
<%= bkst.description %>
<%- end -%>
Create: <%= bkst.created_at %>
Update: <%= bkst.updated_at %>
__END
      else
        ds = M::BackupStorage.dataset
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
