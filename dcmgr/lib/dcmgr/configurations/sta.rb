# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    class Sta < Configuration

      class RawBackingStore < Configuration
        param :snapshot_tmp_dir, :default=>'/var/tmp'

        def validate(errors)
          unless File.directory?(@config[:snapshot_tmp_dir])
            errors << "Could not find the snapshot_tmp_dir: #{@config[:snapshot_tmp_dir]}"
          end
        end
      end

      DSL do
        # Backing Store Driver
        # raw, zfs, ifs
        def backing_store_driver(driver, &blk)
          @config[:backing_store] = driver
          @config["#{driver}_backing_store"] = RawBackingStore.new.tap {
            parse_dsl(&blk) if blk
          }
        end
      end
      
      param :tmp_dir, :default=>'/var/tmp'
      
      # iSCSI Target Driver
      # comstar, sun_iscsi, linux_iscsi
      param :iscsi_target, :default=>'linux_iscsi'

      # Initiator address is IP or ALL
      param :initiator_address,  :default=>'ALL'

      def validate(errors)
        if @config[:iscsi_target].nil?
          errors << "iscsi_target is not set"
        end

        unless %w(comstart sun_iscsi linux_iscsi ifs_iscsi).member?(@config[:iscsi_target])
          errors << "Unknown value for iscsi_target: #{@config[:iscsi_target]}"
        end
        unless %w(raw zfs ifs).member?(@config[:backing_store])
          errors << "Unknown value for backing_store: #{@config[:backing_store]}"
        end
      end
    end
  end
end
