# -*- coding: utf-8 -*-

require 'tmpdir'

module Dcmgr
  module Drivers
    class LinuxLocalStore < LocalStore
      include Dcmgr::Logger
      include Helpers::Cgroup::CgroupContextProvider
      include Helpers::CliHelper

      def deploy_image(inst,ctx)
        # setup vm data folder
        FileUtils.mkdir(ctx.inst_data_dir) unless File.exists?(ctx.inst_data_dir)
        img_src_uri = inst[:image][:backup_object][:uri]
        vmimg_basename = inst[:image][:backup_object][:uuid]
        is_cacheable = inst[:image][:is_cacheable]

        # TODO: Does not support tgz file format in the future.
        vmimg_basename += '.tar.gz' if inst[:image][:file_format] == 'tgz'

        Task::TaskSession.current[:backup_storage] = inst[:image][:backup_object][:backup_storage]
        @bkst_drv_class = BackupStorage.driver_class(inst[:image][:backup_object][:backup_storage][:storage_type])
        
        logger.info("Deploying image file: #{inst[:image][:uuid]}: #{ctx.os_devpath}")
        if Dcmgr.conf.local_store.enable_image_caching && is_cacheable
          FileUtils.mkdir_p(vmimg_cache_dir) unless File.exists?(vmimg_cache_dir)
          download_to_local_cache(inst[:image][:backup_object], vmimg_basename, is_cacheable)
        else
          logger.info("Downloading image file: #{ctx.os_devpath}")
          invoke_task(@bkst_drv_class,
                      :download, [inst[:image][:backup_object], vmimg_cache_path(vmimg_basename, is_cacheable)])
        end
        
        logger.debug("copying #{vmimg_cache_path(vmimg_basename, is_cacheable)} to #{ctx.os_devpath}")

        case inst[:image][:file_format]
        when "raw"
          container_type = detect_container_type(vmimg_cache_path(vmimg_basename, is_cacheable))
          # save the container type to local file
          File.open(File.expand_path('container.format', ctx.inst_data_dir), 'w') { |f|
            f.write(container_type.to_s)
          }
          case container_type
          when :tgz
            Dir.mktmpdir(nil, ctx.inst_data_dir) { |tmpdir|
              # expect only one file is contained.
              lst = shell.run!("tar -ztf #{vmimg_cache_path(vmimg_basename, is_cacheable)}").out.split("\n")
              shell.run!("tar -zxS -C %s < %s", [tmpdir, vmimg_cache_path(vmimg_basename, is_cacheable)])
              File.rename(File.expand_path(lst.first, tmpdir), ctx.os_devpath)
            }
          when :gz
            sh("zcat %s | cp --sparse=always /dev/stdin %s",[vmimg_cache_path(vmimg_basename, is_cacheable), ctx.os_devpath])
          when :tar
            sh("tar -xS -C %s < %s", [ctx.inst_data_dir, vmimg_cache_path(vmimg_basename, is_cacheable)])
          else
            sh("cp -p --sparse=always %s %s",[vmimg_cache_path(vmimg_basename, is_cacheable), ctx.os_devpath])
          end
        end

      ensure
        unless Dcmgr.conf.local_store.enable_image_caching && is_cacheable
          File.unlink(vmimg_cache_path(vmimg_basename, is_cacheable)) rescue nil
        else
          delete_local_cache(is_cacheable)
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
      
      def vmimg_cache_path(img_id, is_cacheable)
        File.expand_path(img_id, (Dcmgr.conf.local_store.enable_image_caching && is_cacheable ? vmimg_cache_dir : download_tmp_dir))
      end

      def download_to_local_cache(bo, basename, is_cacheable)
        begin
          if File.mtime(vmimg_cache_path(basename, is_cacheable)) <= File.mtime("#{vmimg_cache_path(basename, is_cacheable)}.md5")
            cached_chksum = File.read("#{vmimg_cache_path(basename, is_cacheable)}.md5").chomp
            if cached_chksum == bo[:checksum]
              # Here is the only case to be able to use valid cached
              # image file.
              logger.info("Checksum verification passed: #{vmimg_cache_path(basename, is_cacheable)}. We will use this copy.")
              return
            else
              logger.warn("Checksum verification failed: #{vmimg_cache_path(basename, is_cacheable)}. #{cached_chksum} (calced) != #{bo[:checksum]} (expected)")
            end
          else
            logger.warn("Checksum cache file is older than the image file: #{vmimg_cache_path(basename, is_cacheable)}")
          end
        rescue SystemCallError => e
          # come here if it got failed with
          # File.mtime()/read(). Expected to catch ENOENT, EACCESS normally.
          logger.error("Failed to check cached image or checksum file: #{e.message}: #{vmimg_cache_path(basename, is_cacheable)}")
        end

        # Any failure cases will reach here to download image file.
        
        File.unlink("#{vmimg_cache_path(basename, is_cacheable)}") rescue nil
        File.unlink("#{vmimg_cache_path(basename, is_cacheable)}.md5") rescue nil

        logger.info("Downloading image file: #{ctx.os_devpath}")
        invoke_task(@bkst_drv_class,
                    :download, [bo, vmimg_cache_path(basename, is_cacheable)])
        
        if Dcmgr.conf.local_store.enable_cache_checksum
          logger.debug("calculating checksum of #{vmimg_cache_path(basename, is_cacheable)}")
          sh("md5sum #{vmimg_cache_path(basename, is_cacheable)} | awk '{print $1}' > #{vmimg_cache_path(basename, is_cacheable)}.md5")
        end
      end

      def delete_local_cache(is_cacheable)
        cached_images =  (Dir.glob(vmimg_cache_path("*", is_cacheable)) - Dir.glob(vmimg_cache_path("*.md5", is_cacheable)))
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
        # use the file command to detect if the image file is gzip commpressed.
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
          :raw
        end
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
