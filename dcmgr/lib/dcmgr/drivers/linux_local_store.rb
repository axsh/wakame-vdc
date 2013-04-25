# -*- coding: utf-8 -*-

require 'tmpdir'
require 'tempfile'
require 'uri'

module Dcmgr
  module Drivers
    class LinuxLocalStore < LocalStore
      include Dcmgr::Logger
      include Helpers::Cgroup::CgroupContextProvider
      include Helpers::CliHelper

      def deploy_image(inst,ctx)
        @ctx = ctx
        # setup vm data folder
        FileUtils.mkdir(ctx.inst_data_dir) unless File.exists?(ctx.inst_data_dir)
        img_src_uri = inst[:image][:backup_object][:uri]
        vmimg_basename = inst[:image][:backup_object][:uuid]

        Task::TaskSession.current[:backup_storage] = inst[:image][:backup_object][:backup_storage]
        @bkst_drv_class = BackupStorage.driver_class(inst[:image][:backup_object][:backup_storage][:storage_type])

        logger.info("Deploying image: #{inst[:image][:uuid]} from #{inst[:image][:backup_object][:uri]} to #{ctx.os_devpath}")
        # cmd_tuple has ["", []] array.
        cmd_tuple = if Dcmgr.conf.local_store.enable_image_caching && inst[:image][:is_cacheable]
                      FileUtils.mkdir_p(vmimg_cache_dir) unless File.exist?(vmimg_cache_dir)
                      download_to_local_cache(inst[:image][:backup_object])
                      logger.debug("Copying #{vmimg_cache_path()} to #{ctx.os_devpath}")
                      
                      ["cat %s", [vmimg_cache_path()]]
                    else
                      if @bkst_drv_class.include?(BackupStorage::CommandAPI)
                        # download_command() returns cmd_tuple.
                        invoke_task(@bkst_drv_class,
                                    :download_command,
                                    [inst[:image][:backup_object], vmimg_tmp_path()])
                      else
                        logger.info("Downloading image file: #{ctx.os_devpath}")
                        invoke_task(@bkst_drv_class,
                                    :download, [inst[:image][:backup_object], vmimg_tmp_path()])
                        logger.debug("Copying #{vmimg_tmp_path()} to #{ctx.os_devpath}")
                        
                        ["cat %s", [vmimg_tmp_path()]]
                      end
                    end
      

        pv_command = "pv -W -f -p -s #{inst[:image][:backup_object][:size]} |"

        case inst[:image][:backup_object][:container_format].to_sym
        when :tgz
          Dir.mktmpdir(nil, ctx.inst_data_dir) { |tmpdir|
            cmd_tuple[0] << "| #{pv_command} tar -zxS -C %s"
            cmd_tuple[1] += [tmpdir]
            shell.run!(*cmd_tuple)

            # Use first file in the tmp directory as image file.
            img_path = Dir["#{tmpdir}/*"].first
            File.rename(img_path, ctx.os_devpath)
          }
        when :gz
          cmd_tuple[0] << "| %s | #{pv_command} cp --sparse=always /dev/stdin %s"
          cmd_tuple[1] += [Dcmgr.conf.local_store.gunzip_command,
                           ctx.os_devpath]
          shell.run!(*cmd_tuple)
        when :tar
          Dir.mktmpdir(nil, ctx.inst_data_dir) { |tmpdir|
            cmd_tuple[0] << "| #{pv_command} tar -xS -C %s"
            cmd_tuple[1] += [tmpdir]
            shell.run!(*cmd_tuple)

            # Use first file in the tmp directory as image file.
            img_path = Dir["#{tmpdir}/*"].first
            File.rename(img_path, ctx.os_devpath)
          }
        else
          cmd_tuple[0] << "| #{pv_command} cp -p --sparse=always /dev/stdin %s"
          cmd_tuple[1] += [ctx.os_devpath]
          shell.run!(*cmd_tuple)
        end

        raise "Image file is not ready: #{ctx.os_devpath}" unless File.exist?(ctx.os_devpath)

      ensure
        File.unlink(vmimg_tmp_path()) rescue nil
      end

      def upload_image(inst, ctx, bo, evcb)
        @ctx = ctx
        @bo = bo

        Task::TaskSession.current[:backup_storage] = bo[:backup_storage]
        @bkst_drv_class = BackupStorage.driver_class(bo[:backup_storage][:storage_type])

        @snapshot_path = take_snapshot_for_backup(@ctx.os_devpath)
        logger.info("#{@snapshot_path}")
        
        # upload image file
        if @bkst_drv_class.include?(BackupStorage::CommandAPI)
          archive_from_snapshot(ctx, @snapshot_path) do |cmd_tuple, chksum_path, size_path|
            cmd_tuple2 = invoke_task(@bkst_drv_class,
                                     :upload_command, [nil, bo])

            cmd_tuple[0] << " | " + cmd_tuple2[0]
            cmd_tuple[1] += cmd_tuple2[1]
            logger.info("Executing command line: " + shell.format_tuple(*cmd_tuple))
            stderr_buf=""
            r = shell.popen4(shell.format_tuple(*cmd_tuple)) do |pid, sin, sout, eout|
              sin.close

              begin
                while l = eout.readline
                  if l =~ /(\d+)/
                    evcb.progress($1.to_f)
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

            chksum = File.read(chksum_path).split(/\s+/).first
            alloc_size = File.read(size_path).split(/\s+/).first

            evcb.setattr(chksum, alloc_size.to_i)
          end
        else
          archive_from_snapshot(ctx, @snapshot_path) do |cmd_tuple, chksum_path, size_path|
            bkup_tmp = Tempfile.new(inst[:uuid], download_tmp_dir)
            begin
              bkup_tmp.close(false)

              cmd_tuple[0] << "> %s"
              cmd_tuple[1] += [bkup_tmp.path]
              logger.info("Executing command line: " + shell.format_tuple(*cmd_tuple))
              stderr_buf=""
              r = shell.popen4(shell.format_tuple(*cmd_tuple)) do |pid, sin, sout, eout|
                sin.close

                begin
                  while l = eout.readline
                    if l =~ /(\d+)/
                      evcb.progress($1.to_f)
                    end
                    stderr_buf << l
                  end
                rescue EOFError
                  # ignore this error
                end
              end
              unless r.exitstatus == 0
                raise "Failed to run archive command: exitcode=#{r.exitstatus}\n#{stderr_buf}"
              end

              alloc_size = File.size(bkup_tmp.path)
              chksum = File.read(chksum_path).split(/\s+/).first

              evcb.setattr(chksum, alloc_size.to_i)

              invoke_task(@bkst_drv_class,
                          :upload, [bkup_tmp.path, bo])
            ensure
              bkup_tmp.unlink rescue nil
            end
          end
        end

        evcb.progress(100)
      ensure
        clean_snapshot_for_backup()
      end

      protected

      def vmimg_cache_dir
        Dcmgr.conf.local_store.image_cache_dir
      end

      def download_tmp_dir
        Dcmgr.conf.local_store.work_dir || '/var/tmp'
      end

      def vmimg_tmp_path(basename=nil)
        basename ||= begin
                       @ctx.inst[:image][:backup_object][:uuid] + (@suffix ? @suffix : "")
                     end
        File.expand_path(basename, download_tmp_dir)
      end

      def vmimg_cache_path(basename=nil)
        basename ||= begin
                       @ctx.inst[:image][:backup_object][:uuid] + (@suffix ? @suffix : "")
                     end
        if Dcmgr.conf.local_store.enable_image_caching && @ctx.inst[:image][:is_cacheable]
          File.expand_path(basename, vmimg_cache_dir)
        else
          File.expand_path(basename, download_tmp_dir)
        end
      end

      # Guess image file name extracted from archive.(.tar, .tar.gz, .tgz...)
      def vmimg_basename
        path = URI.parse(@ctx.inst[:image][:backup_object][:uri]).path
        suffix = Const::BackupObject::CONTAINER_EXTS.keys.find { |i|
          i = ".#{i}" if i !~ /^\./
          File.basename(path)[-i.size, i.size] == i
        }

        if suffix
          File.basename(path, ".#{suffix}")
        else
          File.basename(path)
        end
      end

      def download_to_local_cache(bo)
        delete_local_cache()
        begin
          if File.mtime(vmimg_cache_path()) <= File.mtime("#{vmimg_cache_path()}.md5")
            cached_chksum = File.read("#{vmimg_cache_path()}.md5").chomp
            if cached_chksum == bo[:checksum]
              # Here is the only case to be able to use valid cached
              # image file.
              logger.info("Checksum verification passed: #{vmimg_cache_path()}. We will use this copy.")
              return
            else
              logger.warn("Checksum verification failed: #{vmimg_cache_path()}. #{cached_chksum} (calced) != #{bo[:checksum]} (expected)")
            end
          else
            logger.warn("Checksum cache file is older than the image file: #{vmimg_cache_path()}")
          end
        rescue SystemCallError => e
          # come here if it got failed with
          # File.mtime()/read(). Expected to catch ENOENT, EACCESS normally.
          logger.error("Failed to check cached image or checksum file: #{e.message}: #{vmimg_cache_path()}")
        end

        # Any failure cases will reach here to download image file.

        File.unlink("#{vmimg_cache_path()}") rescue nil
        File.unlink("#{vmimg_cache_path()}.md5") rescue nil

        logger.info("Downloading image file: #{vmimg_cache_path()}")
        cmd_tuple = ["", []]
        if @bkst_drv_class.include?(BackupStorage::CommandAPI)
          cmd_tuple = invoke_task(@bkst_drv_class,
                                  :download_command, [bo, vmimg_cache_path()])
          cmd_tuple[0] << " | tee >( md5sum | awk '{print $1}' > '%s' ) > '%s'"
          cmd_tuple[1] += ["#{vmimg_cache_path()}.md5", vmimg_cache_path()]
          shell.run!(*cmd_tuple)
        else
          invoke_task(@bkst_drv_class,
                      :download, [bo, vmimg_cache_path()])
          if Dcmgr.conf.local_store.enable_cache_checksum
            logger.debug("calculating checksum of #{vmimg_cache_path()}")
            sh("md5sum #{vmimg_cache_path()} | awk '{print $1}' > #{vmimg_cache_path()}.md5")
          end
        end
      end

      def delete_local_cache()
        cached_images =  (Dir.glob(vmimg_cache_path("*")) - Dir.glob(vmimg_cache_path("*.md5")))
        if cached_images.size > Dcmgr.conf.local_store.max_cached_images
          cached_image = cached_images.sort {|a,b|
            File.mtime(a) <=> File.mtime(b)
          }.first

          logger.debug("delete old cache image #{cached_image}")
          File.unlink("#{cached_image}") rescue nil
          File.unlink("#{cached_image}.md5") rescue nil
        end
      end

      def take_snapshot_for_backup(image_path)
        image_path
      end

      def clean_snapshot_for_backup()
      end

      private
      def detect_container_type(path)
        # use the file command to detect if the image file is gzip
        # commpressed.
        raise "File does not exist: #{path}" unless File.exist?(path)
        file_type1=shell.run!("/usr/bin/file -b %s", [path]).out
        case file_type1
        when /^gzip compressed data,/
          gzip_inside=shell.run!("/usr/bin/file -b -z %s", [path]).out
          if gzip_inside =~ /^POSIX tar archive /
            :tgz
          else
            :gz
          end
        when /^POSIX tar archive /
          :tar
        else
          :none
        end
      end

      def detect_suffix_type(path)
        raise ArgumentError unless path.is_a?(String)
        suffix = Const::BackupObject::CONTAINER_EXTS.keys.find { |i|
          i = ".#{i}" if i !~ /^\./
          File.basename(path)[-i.size, i.size] == i
        }
        return :none if suffix.nil?
        Const::BackupObject::CONTAINER_EXTS[suffix]
      end

      def archive_from_snapshot(ctx, snapshot_path, &blk)
        chksum_path = File.expand_path('md5', ctx.inst_data_dir)
        size_path = File.expand_path('size', ctx.inst_data_dir)

        fstat = File.stat(snapshot_path)
        fstat.instance_eval do
          def block_size
            blocks * 512 * 1024
          end
        end
        # set approx file size estimated from the block count since the target
        # file might be sparsed.
        pv_command = "pv -W -f -n -s %s"

        cmd_tuple = case ctx.inst[:image][:backup_object][:container_format].to_sym
                    when :tgz
                      ["tar -cS -C %s %s | #{pv_command} | %s", [File.dirname(snapshot_path),
                                                                 File.basename(snapshot_path),
                                                                 fstat.block_size,
                                                                 Dcmgr.conf.local_store.gzip_command]]
                    when :tar
                      ["tar -cS -C %s %s | #{pv_command}", [File.dirname(snapshot_path),
                                                            File.basename(snapshot_path),
                                                            fstat.block_size]]
                    when :gz
                      ["cp -p --sparse=always %s /dev/stdout | #{pv_command} | %s",[snapshot_path,
                                                                                    fstat.size,
                                                                                    Dcmgr.conf.local_store.gzip_command]]
                    else
                      ["cp -p --sparse=always %s /dev/stdout | #{pv_command}", [snapshot_path, fstat.size]]
                    end

        # Insert reporting part for md5sum and archived byte size.
        cmd_tuple[0] << " | tee >(md5sum > '%s') >(wc -c > '%s')"
        cmd_tuple[1] += [chksum_path, size_path]

        blk.call(cmd_tuple, chksum_path, size_path)
      ensure
        File.unlink(chksum_path) rescue nil
        File.unlink(size_path) rescue nil
      end

    end
  end
end
