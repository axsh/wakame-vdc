# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    class Sta < Configuration

      param :tmp_dir, :default=>'/var/tmp'
      
      # iSCSI Target Driver
      # comstar, sun_iscsi, linux_iscsi
      param :iscsi_target, :default=>'linux_iscsi'

      # Initiator address is IP or ALL
      param :initiator_address,  :default=>'ALL'

      # Backing Store Driver
      # raw, zfs, ifs
      param :backing_store, :default=>'raw'
      
      def validate(errors)
        if @config[:iscsi_target].nil?
          errors << "iscsi_target is not set"
        end

        unless %w(comstart sun_iscsi linux_iscsi).member?(@config[:iscsi_target])
          errors << "Unknown value for iscsi_target: #{@config[:iscsi_target]}"
        end
        unless %w(raw zfs ifs).member?(@config[:backing_store])
          errors << "Unknown value for backing_store: #{@config[:backing_store]}"
        end
      end
    end
  end
end
