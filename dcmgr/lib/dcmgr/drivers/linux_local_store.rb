# -*- coding: utf-8 -*-

require 'tmpdir'

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

        # TODO: Does not support tgz file format in the future.
        if inst[:image][:file_format] == 'tgz'
          vmimg_basename += '.tar.gz'
        elsif suffix = Const::BackupObject::CONTAINER_EXTS.keys.map {|i| i.size > 0 && i !~ /^\./ ? ".#{i}" : i}.find { |i|
            File.basename(img_src_uri)[-i.size, i.size] == i
          }
          @suffix = suffix
        end

        Task::TaskSession.current[:backup_storage] = inst[:image][:backup_object][:backup_storage]
        @bkst_drv_class = BackupStorage.driver_class(inst[:image][:backup_object][:backup_storage][:storage_type])
        
        logger.info("Deploying image file: #{inst[:image][:uuid]}: #{ctx.os_devpath}")
        # cmd_tuple has ["", []] array.
        cmd_tuple =  if Dcmgr.conf.local_store.enable_image_caching && inst[:image][:is_cacheable]
                       FileUtils.mkdir_p(vmimg_cache_dir) unless File.exist?(vmimg_cache_dir)
                       download_to_local_cache(inst[:image][:backup_object])
                       
                       ["cat %s", [vmimg_cache_path()]
                      else
                        if @bkst_drv_class.include?(BackupStorage::CommandAPI)
                          # download_command() returns cmd_tuple.
                          invoke_task(@bkst_drv_class,
                                      :download_command,
                                      [inst[:image][:backup_object], vmimg_cache_path()])
                        else
                          logger.info("Downloading image file: #{ctx.os_devpath}")
                          invoke_task(@bkst_drv_class,
                                      :download, [inst[:image][:backup_object], vmimg_cache_path()])
                          ["cat %s", [vmimg_cache_path()]
                        end
                      end
        
        logger.debug("copying #{vmimg_cache_path()} to #{ctx.os_devpath}")

        #container_type = detect_container_type(vmimg_cache_path())
        container_type = detect_suffix_type(vmimg_cache_path())
        # save the container type to local file
        File.open(File.expand_path('container.format', ctx.inst_data_dir), 'w') { |f|
          f.write(container_type.to_s)
        }
        
        case container_type
        when :tgz
          Dir.mktmpdir(nil, ctx.inst_data_dir) { |tmpdir|
            # expect only one file is contained.
            lst = shell.run!("tar -ztf #{vmimg_cache_path()}").out.split("\n")
            cmd_tuple[0] << "| tar -zxS -C %s"
            cmd_tuple[1] += [tmpdir]
            shell.run!(*cmd_tuple)
            File.rename(File.expand_path(lst.first, tmpdir), ctx.os_devpath)
          }
        when :gz
          cmd_tuple[0] << "| %s | cp --sparse=always /dev/stdin %s"
          cmd_tuple[1] += [Dcmgr.conf.local_store.gunzip_command,
                           ctx.os_devpath]
          shell.run!(*cmd_tuple)
        when :tar
          cmd_tuple[0] << "| tar -xS -C %s"
          cmd_tuple[1] += [ctx.inst_data_dir]
          shell.run!(*cmd_tuple)
        else
          cmd_tuple[0] << "| cp -p --sparse=always /dev/stdin %s"
          cmd_tuple[1] += [ctx.os_devpath]
          shell.run!(*cmd_tuple)
        end

        case inst[:image][:file_format]
        when "raw"
        else
          raise "Unsupported image file format: #{inst[:image][:file_format]}"
        end

      ensure
        unless Dcmgr.conf.local_store.enable_image_caching && @ctx.inst[:image][:is_cacheable]
          File.unlink(vmimg_cache_path()) rescue nil
        end
      end

      def upload_image(inst, ctx, bo, evcb)

        bkup_tmp_path = File.expand_path("#{inst[:uuid]}.tmp", download_tmp_dir)
        take_snapshot_for_backup()

        chksum, alloc_size = archive_from_snapshot(ctx, ctx.os_devpath, bkup_tmp_path)
        evcb.setattr(chksum, alloc_size)

        # upload image file
        Task::TaskSession.current[:backup_storage] = bo[:backup_storage]
        invoke_task(BackupStorage.driver_class(bo[:backup_storage][:storage_type]),
                    :upload, [bkup_tmp_path, bo])
        evcb.progress(100)
      ensure
        clean_snapshot_for_backup()
        File.unlink(bkup_tmp_path) rescue nil
      end

      protected

      def vmimg_cache_dir
        Dcmgr.conf.local_store.image_cache_dir
      end

      def download_tmp_dir
        Dcmgr.conf.local_store.work_dir || '/var/tmp'
      end
      
      def vmimg_cache_path(basename=nil)
        basename ||= begin
                       @ctx.inst[:image][:backup_object][:uuid] + (@suffix ? @suffix : "")
                     end
        
        File.expand_path(basename, (Dcmgr.conf.local_store.enable_image_caching && @ctx.inst[:image][:is_cacheable] ? vmimg_cache_dir : download_tmp_dir))
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

      def take_snapshot_for_backup()
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

      def archive_from_snapshot(ctx, snapshot_path, bkup_tmp_path)
        chksum_path = File.expand_path('md5', ctx.inst_data_dir)
        
        container_format = nil
        if File.exists?(File.expand_path('container.format', ctx.inst_data_dir))
          container_format = File.read(File.expand_path('container.format', ctx.inst_data_dir)).chomp
        end

        case container_format.to_sym
        when :tgz
          shell.run!("tar -cS -C %s %s | %s | tee >( md5sum > %s) > %s", [File.dirname(snapshot_path),
                                                                          File.basename(snapshot_path),
                                                                          Dcmgr.conf.local_store.gzip_command,
                                                                          chksum_path,
                                                                          bkup_tmp_path])
        when :tar
          shell.run!("tar -cS -C %s %s | tee >( md5sum > %s) > %s", [File.dirname(snapshot_path),
                                                                     File.basename(snapshot_path),
                                                                     chksum_path,
                                                                     bkup_tmp_path])
        when :gz
          shell.run!("cp -p --sparse=always %s /dev/stdout | %s | tee >( md5sum > %s) > %s", [snapshot_path,
                                                                                              Dcmgr.conf.local_store.gzip_command,
                                                                                              chksum_path,
                                                                                              bkup_tmp_path])
        else
          shell.run!("cp -p --sparse=always %s %s", [snapshot_path, bkup_tmp_path])
          shell.run!("md5sum %s > %s", [bkup_tmp_path, chksum_path])
        end
        
        alloc_size = File.size(bkup_tmp_path)
        chksum = File.read(chksum_path).split(/\s+/).first

        [chksum, alloc_size]
      ensure
        if File.exists?(chksum_path)
          File.unlink(chksum_path) rescue nil
        end
      end
      
    end
  end
end
