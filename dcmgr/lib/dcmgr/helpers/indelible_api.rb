# -*- coding: utf-8 -*-

module Dcmgr::Helpers::IndelibleApi
  private
  def ifsutils(uri_suffix, cmd, params = {}, &blk)
    call_ifs_api(@webapi_ip, @webapi_port, :ifsutils, uri_suffix, cmd, params, &blk)
  end

  def ifs_iscsi(uri_suffix, cmd, params = {}, &blk)
    call_ifs_api(@webapi_ip, @webapi_port, :iscsi, uri_suffix, cmd, params, &blk)
  end

  def call_ifs_api(ip, port, api_type, uri_suffix, cmd, params = {}, &blk)
    params[:cmd] = cmd

    uri = "http://#{ip}:#{port}/#{api_type}/#{uri_suffix}?"
    uri.concat params.to_a.map { |i| "#{i.first}=#{i.last}" }.join("&")

    logger.debug "Calling Indelibe FS server: " + uri

    JSON.parse(Net::HTTP.get(URI(uri))).tap { |output|
      blk.call(output) if block_given?
    }
  end

  def directory_exists?(dir)
    result = ifsutils(dir, :list)
    result["error"].nil? && result["list"].is_a?(Array)
  end
end
