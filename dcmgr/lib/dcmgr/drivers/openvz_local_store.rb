# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/openvz_config.rb'

module Dcmgr
  module Drivers
    class OpenvzLocalStore < LocalStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      
      def deploy_image(inst,ctx)
        # load openvz conf
        config = OpenvzConfig.new

        # setup vm data folder
        vm_data_dir = ctx.inst_data_dir
        FileUtils.mkdir(vm_data_dir) unless File.exists?(vm_data_dir)
        
        # vm image file
        img_src = inst[:image][:source]

        # setup vm image cache folder
        vmimg_cache_dir = File.expand_path("cache", config.template)
        FileUtils.mkdir_p(vmimg_cache_dir) unless File.exists?(vmimg_cache_dir)

        # vm image cache
        vmimg_basename = File.basename(img_src[:uri])
        vmimg_cache_path = File.expand_path(vmimg_basename, vmimg_cache_dir)

        logger.debug("preparing #{vmimg_cache_path}")

        # download vm image if vm image cache does not exists
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
        
        case inst[:image][:file_format]
        when "raw"
          case vmimg_cache_path
          when /\.gz$/
            sh("zcat %s | cp --sparse=always /dev/stdin %s",[vmimg_cache_path, ctx.os_devpath])
          else
            sh("cp -p --sparse=always %s %s",[vmimg_cache_path, ctx.os_devpath])
          end
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
