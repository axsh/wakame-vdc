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
        # copy image file
        img_src = inst[:image][:source]
        os_devpath = ctx.os_devpath

        # vmimage cache
        vmimg_cache_dir = File.expand_path("_base", ctx.node.manifest.config.vm_data_dir)
        FileUtils.mkdir_p(vmimg_cache_dir) unless File.exists?(vmimg_cache_dir)
        vmimg_basename = File.basename(img_src[:uri])
        vmimg_cache_path = File.expand_path(vmimg_basename, vmimg_cache_dir)

        logger.debug("preparing #{os_devpath}")

        # vmimg cached?
        unless File.exists?(vmimg_cache_path)
          logger.debug("copying #{img_src[:uri]} to #{vmimg_cache_path}")
          paralell_curl("#{img_src[:uri]}", "#{vmimg_cache_path}")
        else
          md5sum = sh("md5sum #{vmimg_cache_path}")
          if md5sum[:stdout].split(' ')[0] == inst[:image][:md5sum]
            logger.debug("verified vm cache image: #{vmimg_cache_path}")
          else
            logger.debug("not verified vm cache image: #{vmimg_cache_path}")
            sh("rm -f %s", [vmimg_cache_path])
            tmp_id = Isono::Util::gen_id
            logger.debug("copying #{img_src[:uri]} to #{vmimg_cache_path}")
            paralell_curl("#{img_src[:uri]}", "#{vmimg_cache_path}.#{tmp_id}")

            sh("mv #{vmimg_cache_path}.#{tmp_id} #{vmimg_cache_path}")
            logger.debug("vmimage cache deployed on #{vmimg_cache_path}")
          end
        end
        
        ####
        logger.debug("copying #{vmimg_cache_path} to #{os_devpath}")
        case vmimg_cache_path
        when /\.gz$/
          sh("zcat %s | cp --sparse=always /dev/stdin %s",[vmimg_cache_path, os_devpath])
        else
          sh("cp -p --sparse=always %s %s",[vmimg_cache_path, os_devpath])
        end
        
      end
      
      private
      def paralell_curl(url, output_path)
        script_root_path = File.join(File.expand_path('../../../../',__FILE__), 'script')
        sh("#{script_root_path}/pararell-curl.sh --url=#{url} --output_path=#{output_path}")
      end
    end
  end
end
