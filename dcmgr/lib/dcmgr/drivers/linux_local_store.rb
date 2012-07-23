# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LinuxLocalStore < LocalStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      
      def deploy_image(inst,ctx)
        # setup vm data folder
        inst_data_dir = ctx.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)
        img_src_uri = inst[:image][:backup_object][:uri]
        vmimg_basename = inst[:image][:backup_object][:uuid]
        is_cacheable = inst[:image][:is_cacheable]

        logger.debug("Deploying image file: #{inst[:uuid]}: #{ctx.os_devpath}")

        if Dcmgr.conf.local_store.enable_image_caching && is_cacheable
          FileUtils.mkdir_p(vmimg_cache_dir) unless File.exists?(vmimg_cache_dir)
          download_to_local_cache(img_src_uri, vmimg_basename, inst[:image][:backup_object][:checksum], is_cacheable)
        else
          parallel_curl(img_src_uri, vmimg_cache_path(vmimg_basename, is_cacheable))
        end
        
        logger.debug("copying #{vmimg_cache_path(vmimg_basename, is_cacheable)} to #{ctx.os_devpath}")

        case inst[:image][:file_format]
        when "raw"
          # use the file command to detect if the image file is gzip commpressed.
          if  `/usr/bin/file #{vmimg_cache_path(vmimg_basename, is_cacheable)}` =~ /: gzip compressed data,/
            sh("zcat %s | cp --sparse=always /dev/stdin %s",[vmimg_cache_path(vmimg_basename, is_cacheable), ctx.os_devpath])
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
        snapshot_stg = Dcmgr::Drivers::BackupStorage.snapshot_storage(bo[:backup_storage])
        
        bkup_tmp_path = File.expand_path("#{inst[:uuid]}.tmp", download_tmp_dir)
        take_snapshot_for_backup()
        sh("cp -p --sparse=always %s /dev/stdout | gzip -f > %s", [ctx.os_devpath, bkup_tmp_path])
        alloc_size = File.size(bkup_tmp_path)
        res = sh("md5sum %s | awk '{print $1}'", [bkup_tmp_path])
        
        evcb.setattr(res[:stdout].chomp, alloc_size)

        # upload image file
        snapshot_stg.upload(bkup_tmp_path, bo)
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
        ENV['TMPDIR'] || ENV['TMP'] || '/var/tmp'
      end
      
      def vmimg_cache_path(img_id, is_cacheable)
        File.expand_path(img_id, (Dcmgr.conf.local_store.enable_image_caching && is_cacheable ? vmimg_cache_dir : download_tmp_dir))
      end

      def download_to_local_cache(img_src_uri, basename, checksum, is_cacheable)
        begin
          if File.mtime(vmimg_cache_path(basename, is_cacheable)) <= File.mtime("#{vmimg_cache_path(basename, is_cacheable)}.md5")
            cached_chksum = File.read("#{vmimg_cache_path(basename, is_cacheable)}.md5").chomp
            if cached_chksum == checksum
              # Here is the only case to be able to use valid cached
              # image file.
              logger.info("Checksum verification passed: #{vmimg_cache_path(basename, is_cacheable)}. We will use this copy.")
              return
            else
              logger.warn("Checksum verification failed: #{vmimg_cache_path(basename, is_cacheable)}. #{cached_chksum} (calced) != #{checksum} (expected)")
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
        
        parallel_curl(img_src_uri, vmimg_cache_path(basename, is_cacheable))
        
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
      def parallel_curl(url, output_path)
        logger.debug("downloading #{url} as #{output_path}")
        sh("#{Dcmgr.conf.script_root_path}/parallel-curl.sh --url=#{url} --output_path=#{output_path}")
      end
    end
  end
end
