# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class Comstar < IscsiTarget
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      # ref: http://nkjmkzk.net/?p=2022
      def create(ctx)
        @volume = ctx.volume.dup

        # $ man itadm
        #
        # target_node_name
        # An iSCSI Initiator Node Context  is  identified  by
        # its Initiator Node Name, formatted in either IQN or EUI for-
        # mat (see RFC 3720). For example:
        #  iqn.1986-03.com.sun:01:e00000000000.47d55444
        #  eui.02004567A425678D
        #
        # [TODO]
        iqn_prefix = "iqn.2010-09.jp.wakame"
        target_node = "#{iqn_prefix}:#{@volume[:account_id]}.#{@volume[:uuid]}"

        # target
        sh("itadm create-target -n %s", [target_node])

        # target group
        target_group = "tg:#{@volume[:account_id]}.#{@volume[:uuid]}"
        # target must be offline.
        # $ stmfadm create-tg a-shpoolxx.vol-chgqqw21
        # => stmfadm: STMF target must be offline
        #
        sh("stmfadm offline-target %s", [target_node])
        sh("stmfadm create-tg %s", [target_group])
        sh("stmfadm add-tg-member -g %s %s", [target_group, target_node])
        sh("stmfadm online-target %s", [target_node])

        sh("itadm list-target -v %s", [target_node])

        # host group
        host_group = "hg:#{@volume[:account_id]}.#{@volume[:uuid]}"
        sh("stmfadm create-hg %s", [host_group])
        sh("stmfadm add-hg-member -g %s %s", [host_group, target_node])

        # zvol has already created by backing storep
        zvol_path = "/dev/zvol/rdsk/#{@volume[:storage_pool][:export_path]}/#{@volume[:uuid]}"

        # logical_unit
        logical_unit = sh("sbdadm create-lu %s | grep -w %s", [zvol_path, zvol_path])
        guid = logical_unit[:stdout].split(' ')[0]

        # view
        sh("stmfadm add-view -t %s -h %s %s", [target_group, host_group, guid])
        logical_unit = sh("stmfadm list-view -l %s", [guid])
        logical_unit = logical_unit[:stdout].downcase.split("\n").select {|row| row.strip!}

        opt = {:iqn => target_node, :lun=>logical_unit[2].split(": ").last, :guid => guid, :hg => host_group, :tg => target_group}
      end

      def delete(ctx)
        @volume = ctx.volume

        guid = @volume[:transport_information][:guid]
        iqn =  @volume[:transport_information][:iqn]
        target_group =  @volume[:transport_information][:tg]
        host_group   =  @volume[:transport_information][:hg]

        sh("stmfadm offline-target %s", [iqn])
        sh("itadm delete-target %s", [iqn])

        sh("stmfadm delete-lu %s", [guid])
        sh("stmfadm delete-tg %s", [target_group])
        sh("stmfadm delete-hg %s", [host_group])
      end
    end
  end
end
