# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LinuxIscsi < IscsiTarget
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::StaTgtHelper

      def create(ctx)
        @volume    = ctx.volume
        @volume_id = ctx.volume_id
        @node      = ctx.node

        iqn_prefix = "iqn.2010-09.jp.wakame"
        vol_path = File.join(@volume[:storage_node][:export_path], @volume[:account_id], @volume[:uuid]) 
        
        iscsi = {}
        iscsi[:iqn] = "#{iqn_prefix}:#{@volume[:account_id]}.#{@volume[:uuid]}"
        iscsi[:tid] = @volume[:id]
        iscsi[:lun] = 1
        iscsi[:backing_store] = vol_path
        iscsi[:initiator_address] = @node.manifest.config.initiator_address 
        
        register_target(iscsi[:tid], iscsi[:iqn])
        register_logicalunit(iscsi[:tid], iscsi[:lun], iscsi[:backing_store])
        bind_target(iscsi[:tid], iscsi[:initiator_address])
        
        opt = { :iqn => iscsi[:iqn], :lun => iscsi[:lun], :tid => iscsi[:tid], :backing_store => iscsi[:backing_store] }
      end

      def delete(ctx)
        @volume = ctx.volume
        sh("/usr/sbin/tgt-admin --delete #{@volume[:transport_information][:iqn]}")
      end
    end
  end
end
