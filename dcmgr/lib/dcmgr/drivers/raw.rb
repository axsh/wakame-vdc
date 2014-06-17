# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class Raw < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::ByteUnit

      def_configuration do
        param :export_path
        param :local_backup_path
        param :snapshot_tmp_dir, :default=>'/var/tmp'

        def validate(errors)
          super

          unless File.directory?(@config[:export_path])
            errors << "Could not find the export_path: #{@config[:export_path]}"
          end

          unless File.directory?(@config[:local_backup_path])
            errors << "Could not find the local_backup_path: #{@config[:local_backup_path]}"
          end

          unless File.directory?(@config[:snapshot_tmp_dir])
            errors << "Could not find the snapshot_tmp_dir: #{@config[:snapshot_tmp_dir]}"
          end
        end
      end

      module ContainerFormat
        require 'tmpdir'
        require 'tempfile'
        require 'uri'
        PV_COMMAND='pv -W -f -p -s %d'

        # Basically, deploy_volume() deals with image file as:
        #   1. download the image file.
        #   2. extreact the image file if it is compressed or archived.
        # For more detail, there are standard & stream modes to run:
        #  Standard mode:
        #    1. download the image file to temporaly directory.
        #    2. extract the image file to the export location.
        #  Stream mode:
        #    1. build single piped command line that performs both downloading
        #       and extracting. also reports the progress percentage
        #       to the temp file.
        #    2. run the command line.
        def deploy_volume_from_backup_object(sta_ctx, local_backup_path=nil)
          raise "" if sta_ctx.volume.nil?
          raise "" if sta_ctx.backup_object.nil?

          @volume = sta_ctx.volume
          @backup_object = sta_ctx.backup_object

          @backup_storage = BackupStorage.driver_class(@backup_object[:backup_storage][:storage_type]).new

          logger.info "Deploying volume: %s from %s to #{volume_path}" %
            [@volume[:uuid], @backup_object[:uri]]

          cmd_tuple_list = []

          cmd_tuple_list <<
            if local_backup_path
              ["cat %s", [local_backup_path]]
            elsif @backup_storage.class.include?(BackupStorage::CommandAPI)
              # download_command() returns cmd_tuple.
              @backup_storage.download_command(@backup_object, download_temp_path(@volume[:volume_device][:path]))
            else
              logger.info("Downloading image file: #{volume_path}")
              @backup_storage.download(@backup_object, download_temp_path(@volume[:volume_device][:path]))
              logger.info("Copying #{download_temp_path(@volume[:volume_device][:path])} to #{volume_path}")
            
              ["cat %s", [download_temp_path(@volume[:volume_device][:path])]]
            end

          pv_command = [PV_COMMAND, [@backup_object[:size]]]

          case @backup_object[:container_format].to_sym
          when :tgz
            Dir.mktmpdir(nil, download_temp_dir) { |tmpdir|
              cmd_tuple_list << pv_command
              cmd_tuple_list << ["tar -zxS -C %s", [tmpdir]]
              shell.run!(build_piped_command(cmd_tuple_list))

              # Use first file in the tmp directory as image file.
              img_path = Dir["#{tmpdir}/*"].first
              File.rename(img_path, volume_path)
            }
          when :gz
            cmd_tuple_list << 'gunzip'
            cmd_tuple_list << pv_command
            cmd_tuple_list << ['cp --sparse=always /dev/stdin %s', [volume_path]]
            shell.run!(build_piped_command(cmd_tuple_list))
          when :tar
            Dir.mktmpdir(nil, download_temp_dir) { |tmpdir|
              cmd_tuple_list << pv_command
              cmd_tuple_list << ["tar -xS -C %s", [tmpdir]]
              shell.run!(build_piped_command(cmd_tuple_list))

              # Use first file in the tmp directory as image file.
              img_path = Dir["#{tmpdir}/*"].first
              File.rename(img_path, volume_path)
            }
          else
            cmd_tuple_list << pv_command
            cmd_tuple_list << ['cp --sparse=always /dev/stdin %s', [volume_path]]
            shell.run!(build_piped_command(cmd_tuple_list))
          end

          raise "Image file is not ready: #{volume_path}" unless File.exist?(volume_path)
        ensure
          File.unlink(download_temp_path(@volume[:volume_device][:path])) rescue nil
        end

        def local_copy_and_archive_volume(ctx, src_path, dest_path, progress_callback)
          @ctx = ctx
          @volume= ctx.volume
          @backup_object = ctx.backup_object

          tmpdir = Dir.mktmpdir(nil, download_temp_dir)
          chksum_path = File.expand_path('md5', tmpdir)
          size_path = File.expand_path('size', tmpdir)

          logger.info("Local copy and archive: #{@backup_object_id}")
          cmd = build_piped_command(build_archive_command(@ctx, src_path, chksum_path, size_path))
          cmd += ('> %s' % [dest_path])
          run_with_progress(cmd, progress_callback)

          chksum = File.read(chksum_path).split(/\s+/).first
          alloc_size = File.read(size_path).split(/\s+/).first

          # Report archived file size & md5 checksum
          progress_callback.setattr(chksum, alloc_size.to_i)
          progress_callback.progress(100)
        end

        def upload_and_archive_volume(ctx, src_path, progress_callback)
          @ctx = ctx
          @volume= ctx.volume
          @backup_object = ctx.backup_object

          @bkst_drv_class = BackupStorage.driver_class(@backup_object[:backup_storage][:storage_type]).new

          tmpdir = Dir.mktmpdir(nil, download_temp_dir)
          chksum_path = File.expand_path('md5', tmpdir)
          size_path = File.expand_path('size', tmpdir)

          if @bkst_drv_class.class.include?(Drivers::BackupStorage::CommandAPI)
            logger.info("Stream upload: #{@backup_object_id}")
            # 1. build piped command line which does both compress
            #    and upload.
            # 2. Run the commoand line.
            cmd_list = build_archive_command(@ctx, src_path, chksum_path, size_path)
            cmd_list << @bkst_drv_class.upload_command(nil, @backup_object)

            run_with_progress(build_piped_command(cmd_list), progress_callback)
            chksum = File.read(chksum_path).split(/\s+/).first
            alloc_size = File.read(size_path).split(/\s+/).first
          else
            logger.info("Convert and upload: #{@backup_object_id}")
            # 1. Covert original image to archived/compressed format
            #    and save to temporary file.
            # 2. Upload the temporary file to the destination
            bkup_tmp = Tempfile.new(volume[:uuid], download_temp_dir)
            begin
              bkup_tmp.close(false)

              cmd = build_piped_command(build_archive_command(@ctx, src_path, chksum_path, size_path))
              cmd += ('> %s' % [bkup_tmp.path])
              run_with_progress(cmd, progress_callback)

              alloc_size = File.size(bkup_tmp.path)
              chksum = File.read(chksum_path).split(/\s+/).first

              @bkst_drv_class.upload(bkup_tmp.path, @backup_object)
            ensure
              bkup_tmp.unlink rescue nil
            end
          end
          # Report archived file size & md5 checksum
          progress_callback.setattr(chksum, alloc_size.to_i)
          progress_callback.progress(100)
        ensure
          if File.directory?(tmpdir)
            FileUtils.remove_entry_secure(tmpdir)
          end
        end

        private
        def volume_path
        end

        def download_temp_dir
        end

        def download_temp_path(real_path)
          File.expand_path(real_path, download_temp_dir())
        end

        def build_piped_command(cmd_tuple_list)
          cmd_tuple_list.map { |t|
            if t.is_a?(Array) && t.size == 2 && t[0].is_a?(String) && t[1].is_a?(Array)
              t[0] % t[1]
            elsif t.is_a?(Array) && t.size > 1 && t[0].is_a?(String)
              t[0] % t.slice(1..-1)
            elsif t.is_a?(String)
              t
            end
          }.join(' | ')
        end

        def build_archive_command(ctx, src_path, chksum_path, size_path)
          fstat = File.stat(src_path)
          fstat.instance_eval do
            def block_size
              blocks * 512 * 1024
            end
          end

          cmd_tuple_list = []

          # set approx file size estimated from the block count since the target
          # file might be sparsed.
          pv_command = [PV_COMMAND, [fstat.block_size.to_s]]

          # build archive command.
          cmd_tuple = case ctx.backup_object[:container_format].to_sym
          when :tgz
            # tar | pv | gzip
            cmd_tuple_list.push(
              ['tar -cS -C %s %s', [File.dirname(src_path),
                                    File.basename(src_path)]
              ],
              pv_command,
              'gzip')
          when :tar
            # tar | pv
            cmd_tuple_list.push(
              ['tar -cS -C %s %s', [File.dirname(src_path),
                                    File.basename(src_path)]
              ],
              pv_command)
          when :gz
            # cp | pv | gzip
            cmd_tuple_list.push(
              ['cp -p --sparse=always %s /dev/stdout', [src_path]],
              pv_command,
              'gzip'
              )
          else
            cmd_tuple_list.push(
              ["cp -p --sparse=always %s /dev/stdout", [src_path]],
              pv_command
            )
          end
          
          # Insert reporting part for md5sum and archived byte size.
          cmd_tuple_list << ["tee >(md5sum > '%s') >(wc -c > '%s')", [chksum_path, size_path]]
          cmd_tuple_list          
        end

        def run_with_progress(cmd, callback)
          stderr_buf=""
          logger.info("Executing command line: " + cmd)
          r = shell.popen4(cmd) do |pid, sin, sout, eout|
            sin.close
            begin
              while l = eout.readline
                if l =~ /(\d+)/
                  # Report transfer progress
                  callback.progress($1.to_f)
                end
                stderr_buf << l
              end
            rescue EOFError
              # ignore this error
            end
          end
          unless r.exitstatus == 0
            raise "Failed to run archive & upload command: exitcode=#{r.exitstatus}\n#{stderr_buf}"
          end
        end
      end

      include ContainerFormat

      include CreateVolumeInterface

      def create_volume_from_local_backup(ctx)
        common_setup(ctx)
        deploy_volume_from_backup_object(ctx, backup_real_path(backup_key))
      end
      
      def create_blank_volume(ctx)
        common_setup(ctx)
        if File.exist?(volume_path)
          raise "volume already exists: #{ctx.volume_id}"
        end

        logger.info("#{ctx.volume_id}: creating blank volume at #{volume_path}")
        
        sh("/bin/dd if=/dev/zero of=#{volume_path} bs=1 count=0 seek=#{ctx.volume[:size]}")
        du_hs(volume_path)
      end
      
      def create_volume_from_backup(ctx)
        common_setup(ctx)
        deploy_volume_from_backup_object(ctx)
      end

      # Obsolete interface to create volume.
      def create_volume(ctx, backup_key = nil)
        common_setup(ctx)
        if @backup_object
          logger.info("creating new volume: id:#{@volume_id} path:#{volume_path} from #{@backup_object[:uuid]}.")
          
          if backup_key
            deploy_volume_from_backup_object(ctx, backup_real_path(backup_key))
          else
            deploy_volume_from_backup_object(ctx)
          end
        else
          create_blank_volume(ctx)
        end
      end

      def delete_volume(ctx)
        common_setup(ctx)
        sh("/bin/rm %s", [volume_path]) if File.exists?(volume_path)
      end

      def create_snapshot(ctx)
        @volume = ctx.volume

        cp_sparse(volume_path, snapshot_path(ctx))
        du_hs(snapshot_path(ctx))
      end

      def delete_snapshot(ctx)
        File.unlink(snapshot_path(ctx)) rescue nil
      end

      def snapshot_path(ctx)
        File.expand_path("#{ctx.volume[:uuid]}.tmp", driver_configuration.snapshot_tmp_dir)
      end

      include BackingStore::ProvideBackupVolume

      def backup_volume(ctx, progress_callback)
        # src volume
        @volume = ctx.volume
        # dest backup
        @backup_object = ctx.backup_object

        @bkst_drv_class = BackupStorage.driver_class(@backup_object[:backup_storage][:storage_type]).new
        if self.local_backup_object?(@backup_object)
          local_copy_and_archive_volume(ctx, volume_path(), backup_real_path(@backup_object[:object_key]), progress_callback)
        else
          upload_and_archive_volume(ctx, volume_path(), progress_callback)
        end
      end

      def delete_backup(ctx)
        File.unlink(backup_real_path(backup_object_key_created(ctx))) rescue nil
      end

      # @return String path to the backup object key by backup_volume().
      #
      # backup_volume(ctx)
      # puts backup_object_key_created(ctx)
      def backup_object_key_created(ctx)
        ctx.backup_object_id
      end

      private
      # overload: 
      def volume_path
        case @volume[:volume_type]
        when 'Dcmgr::Models::LocalVolume'
          File.join(driver_configuration.export_path, @volume[:volume_device][:path])
        when 'Dcmgr::Models::NfsVolume'
          File.join(driver_configuration.export_path, @volume[:volume_device][:path])
        else
          raise "Unsupported volume type: #{@volume[:volume_type]}"
        end
      end

      # overload: 
      def download_temp_dir()
        File.join(driver_configuration.export_path, 'tmp')
      end

      def common_setup(ctx)
        @volume_id   = ctx.volume_id
        @volume      = ctx.volume
        @backup_object    = ctx.backup_object

        unless File.directory?(File.dirname(volume_path))
          raise "Missing base folder: #{File.dirname(volume_path)}"
        end
      end

      # Local backup path
      def backup_real_path(backup_key)
        File.join(driver_configuration.local_backup_path, backup_key)
      end

      def cp_sparse(src, dst)
        sh("/bin/cp -p --sparse=always %s %s",[src, dst])
      end

      def du_hs(path)
        sh("du -hs %s", [path])
        sh("du -hs --apparent-size %s", [path])
      end

    end
  end
end
