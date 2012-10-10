# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LinuxIscsi < IscsiTarget
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      IQN_PREFIX="iqn.2010-09.jp.wakame".freeze

      def create(ctx)
        @volume    = ctx.volume
        @volume_id = ctx.volume_id
        @node      = ctx.node

        vol_path = File.join(@volume[:storage_node][:export_path], @volume[:uuid])

        @volume[:transport_information] = iscsi = {}
        iscsi[:iqn] = "#{IQN_PREFIX}:#{@volume[:uuid]}"
        iscsi[:tid] = pick_next_tid
        iscsi[:lun] = 1
        iscsi[:backing_store] = vol_path

        register(@volume)

        opt = { :iqn => iscsi[:iqn], :lun => iscsi[:lun], :tid => iscsi[:tid], :backing_store => iscsi[:backing_store] }
      end

      def delete(ctx)
        @volume = ctx.volume
        sh("/usr/sbin/tgt-admin --delete #{@volume[:transport_information][:iqn]}")
      end

      def register(volume)
        tinfo = volume[:transport_information]

        # register target
        sh("/usr/sbin/tgtadm --lld iscsi --op new --mode=target --tid=%s --targetname %s", [tinfo[:tid], tinfo[:iqn]])
        # register logical unit
        sh("/usr/sbin/tgtadm --lld iscsi --op new --mode=logicalunit --tid=%s --lun=%s -b %s",
           [tinfo[:tid], tinfo[:lun], tinfo[:backing_store]])
        # bind target
        sh("/usr/sbin/tgtadm --lld iscsi --op bind --mode=target --tid=%s --initiator-address=%s",
           [tinfo[:tid], Dcmgr.conf.initiator_address])
      end

      private
      def pick_next_tid
        # $ sudo /usr/sbin/tgtadm --lld iscsi --op show --mode target | grep '^Target '
        # Target 1: iqn.2010-09.jp.wakame:a-shpoolxx.vol-dw55bba8
        lst = `/usr/sbin/tgtadm --lld iscsi --op show --mode target | grep ^Target`.split("\n")
        max_tid = lst.map { |a| a =~ /^Target\s+(\d+):.*/; $1.to_i; }.max || 0
        max_tid + 1
      end
    end
  end
end
