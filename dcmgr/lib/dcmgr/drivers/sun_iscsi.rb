# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class SunIscsi < IscsiTarget
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def create(ctx)
        @volume    = ctx.volume
        @volume_id = ctx.volume_id
        sh("/usr/sbin/zfs shareiscsi=on %s/%s", [@volume[:storage_node][:export_path], @volume[:uuid]])

        if $?.exitstatus != 0
          raise "failed iscsi target request: #{@volume_id}"
        end
        il = sh("iscsitadm list target -v %s", ["#{@volume[:storage_node][:export_path]}/#{@volume[:uuid]}"])
        if $?.exitstatus != 0
          raise "iscsi target has not be created #{@volume_id}"
        end
        il = il[:stdout].downcase.split("\n").select {|row| row.strip!}
        # :transport_information => {:iqn => "iqn.1986-03.com.sun:02:787bca42-9639-44e4-f115-f5b06ed31817", :lun => 0}
        opt = {:iqn => il[0].split(": ").last, :lun=>il[6].split(": ").last.to_i}
      end

      def delete(ctx)
        @volume = ctx.volume
        sh("/usr/sbin/zfs shareiscsi=off %s/%s", [@volume[:storage_node][:export_path], @volume[:uuid]])
      end
    end
  end
end
