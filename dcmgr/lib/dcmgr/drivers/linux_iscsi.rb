# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LinuxIscsi < IscsiTarget
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def_configuration do
        param :tgtadm_path, :default=>'/usr/sbin/tgtadm'

        # Require to set in sta.conf
        param :export_path

        def validate(errors)
          if config[:export_path].nil?
            errors.add("export_path is unset.")
          elsif !File.exists?(config[:export_path])
            errors.add("The export_path does not exist or have access issue: #{config[:export_path]}")
          end
        end
      end

      def create(ctx)
        @volume    = ctx.volume
        @volume_id = ctx.volume_id

        # iscsi_storage_nodes table entries.
        iscsi = {
          :iqn => iqn_from_ctx,
          :lun => 1, # 0 is reserved by tgt.
        }
        tid = pick_next_tid

        register(tid, iscsi[:iqn], iscsi[:lun], volume_path)

        iscsi
      end

      def delete(ctx)
        @volume = ctx.volume
        @volume_id = ctx.volume_id
        
        sh("/usr/sbin/tgt-admin --delete '%s'", [iqn_from_ctx])
      end

      def register(volume)
        tinfo = volume[:transport_information]

      def register(tid, iqn, lun, bs_path)
        # register target
        tgtadm("--op new --mode=target --tid=%s --targetname %s", [tid, iqn])
        # register logical unit
        tgtadm("--op new --mode=logicalunit --tid=%s --lun=%s --backing-store %s",
               [tid, lun, bs_path])
        tgtadm("--op bind --mode=target --tid=%s --initiator-address=ALL",
               [tid])
      end

      def pick_next_tid
        # $ sudo /usr/sbin/tgtadm --lld iscsi --op show --mode target | grep '^Target '
        # Target 1: iqn.2010-09.jp.wakame:vol-xxxxxxx
        lst = `#{driver_configuration.tgtadm_path} --lld iscsi --op show --mode target | grep ^Target`.split("\n")
        max_tid = lst.map { |a| a =~ /^Target\s+(\d+):.*/; $1.to_i; }.max || 0
        max_tid + 1
      end

      def tgtadm(cmd, args=[])
        sh("#{driver_configuration.tgtadm_path} --lld iscsi " + cmd, args)
      end

      def iqn_from_ctx
        raise "Call after set @volume." if @volume.nil?
        "#{driver_configuration.iqn_prefix}:#{@volume[:uuid]}"
      end

      def volume_path
        raise "Call after set @volume." if @volume.nil?
        File.join(driver_configuration.export_path, @volume[:volume_device][:path])        
      end
      
      def find_tid(iqn)
        lst = `#{driver_configuration.tgtadm_path} --lld iscsi --op show --mode target`.split("\n")
        if lst.find { |l| l =~ /^Target\s+(\d+): #{iqn}/ }
          $1.to_i
        else
          nil
        end
      end
    end
  end
end
