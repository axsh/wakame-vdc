# -*- coding: utf-8 -*-
require 'rexml/document'
require 'uri'

module Dcmgr
  module Helpers
    module SnapshotStorageHelper
      include Dcmgr::Helpers::CliHelper

      def bucket_name(uri)
        uri = URI.parse(uri)
        paths = uri.path.split('/')
        raise "Bucket name needs to be set at the top of path: #{uri}" if paths.size < 2
        path[1]
      end

      def execute(cmd, args)
        script = File.join(Dcmgr.conf.script_root_path, 'storage_service')
        cmd = "/usr/bin/env #{@env.join(' ')} %s " + cmd
        args = [script] + args
        res = sh(cmd, args)

        if res[:stdout] != ''
          doc = REXML::Document.new res[:stdout]
          code = REXML::XPath.match( doc, "//Error/Code/text()" ).to_s
          message = REXML::XPath.match( doc, "//Error/Message/text()" ).to_s
          bucket_name = REXML::XPath.match( doc, "//Error/BucketName/text()" ).to_s
          request_id = REXML::XPath.match( doc, "//Error/RequestId/text()" ).to_s
          host_id = REXML::XPath.match( doc, "//Error/HostId/text()" ).to_s
          error_message = ["Snapshot execute error: ",cmd, code, message, bucket_name, request_id, host_id].join(',')
          raise error_message
        else
          res
        end
      end
    end
  end
end
