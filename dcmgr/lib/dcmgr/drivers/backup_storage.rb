# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  # Backup storage operations.
  # upload/donwload/delete items on the backup stroage.
  class BackupStorage

    # Upload volume file to the backup storage.
    # @param src_path the local path to upload.
    # @param dst_key  destination key(path) to upload. Relative path
    #                 info will be given.
    #
    # Note that the dst_key will have a relative path so that it has to
    # craft the absolete destination using the additional parameter given
    # at creating this object.
    #
    # @example
    #  upload('/home/xxxx/tmp/upload.img', 'to/be/uploaded.img')
    #
    def upload(src_path, dst_key)
      raise NotImplementedError
    end

    # Download volume file from the backup storage.
    # @param src_key  source key(path) to download. Relative path
    #                 info will be given.
    # @param dst_path  local path to download.
    #
    # @example
    #  download('to/be/downloaded.img', '/home/xxxx/images/donwloaded.img')
    def download(src_key, dst_path)
      raise NotImplementedError
    end

    def delete(dst_key)
      raise NotImplementedError
    end
  end
end
  
