# -*- coding: utf-8 -*-
require 'rexml/document'

module Dcmgr
  module Helpers
    module SnapshotStorageHelper
      def execute(cmd, args)
        script_root_path = File.join(File.expand_path('../../../../',__FILE__), 'script')
        script = File.join(script_root_path, 'storage_service')
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
