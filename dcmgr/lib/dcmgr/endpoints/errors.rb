# -*- coding: utf-8 -*-

module Dcmgr
  module Endpoints
    def self.define_error(class_name, status_code, error_code, &blk)
      c = Class.new(APIError)
      c.status_code(status_code)
      c.error_code(error_code)
      c.instance_eval(&blk) if blk
      self.set_error_code_type(error_code, c)
      self.const_set(class_name.to_sym, c)
    end

    @error_code_map = {}
    def self.set_error_code_type(error_code, klass)
      raise TypeError unless klass < APIError
      if @error_code_map.has_key?(error_code)
        if @error_code[error_code] == klass
        else
          raise "Duplicate Error Code Registration: #{klass}, code=#{error_code}"
        end
      else
        @error_code_map[error_code]=klass
      end
    end

    class APIError < StandardError
      
      # HTTP status code of the error.
      def self.status_code(code=nil)
        if code
          @status_code = code
        end
        @status_code || raise("@status_code for the class is not set")
      end

      # Internal error code of the error.
      def self.error_code(code=nil)
        if code
          @error_code = code
        end
        @error_code || raise("@error_code for the class is not set")
      end

      def status_code
        self.class.status_code
      end

      def error_code
        self.class.error_code
      end
    end

    define_error(:UnknownUUIDResource, 404, '100')
    define_error(:UnknownMember, 400, '101')
    define_error(:InvalidCredentialHeaders, 400, '102')
    define_error(:InvalidRequestCredentials, 400, '103')
    define_error(:DisabledAccount, 403, '104')
    define_error(:OperationNotPermitted, 403, '105')
    define_error(:UndefinedVolumeSize, 400, '106')
    define_error(:StoragePoolNotPermitted, 403, '107')
    define_error(:UnknownStoragePool, 404, '108')
    define_error(:OutOfDiskSpace, 400, '109')
    define_error(:DatabaseError, 400, '110')
    define_error(:UndefinedVolumeID, 400, '111')
    define_error(:InvalidDeleteRequest, 400, '112')
    define_error(:UnknownVolume, 404, '113')
    define_error(:UnknownHostPool, 404, '114')
    define_error(:UnknownInstance, 404, '115')
    define_error(:UndefindVolumeSnapshotID, 400, '116')
    define_error(:UnknownVolumeSnapshot, 404, '117')
    define_error(:UndefinedRequiredParameter, 400, '118')
    define_error(:InvalidVolumeSize, 400, '119')
    define_error(:OutOfHostCapacity, 400, '120')
    define_error(:UnknownSshKeyPair, 404, '121')
    define_error(:UndefinedStoragePoolID, 400, '122')
    define_error(:DetachVolumeFailure, 400, '123')
    define_error(:AttachVolumeFailure, 400, '124')
    define_error(:InvalidInstanceState, 400, '125')
    define_error(:DuplicateHostname, 400, '126')
    define_error(:UnknownImageID, 404, '127')
    define_error(:UnknownInstanceSpec, 404, '128')
    define_error(:UnknownNetworkID, 404, '129')
    define_error(:OutOfNetworkCapacity, 400, '130')
    define_error(:InvalidVolumeSnapshotState, 400, '131')


    # netfilter_group
    define_error(:UndefinedNetfilterGroup, 400, '132')
    define_error(:UnknownNetfilterGroup, 400, '133')
    define_error(:NetfilterGroupNotPermitted, 400, '134')
    define_error(:DuplicatedNetfilterGroup, 400, '135')

    define_error(:DuplicateSshKeyName, 400, '136')
    define_error(:InvalidImageID, 400, '137')
    define_error(:InvalidInstanceSpec, 400, '138')
    define_error(:UndefinedInstanceID, 404, '139')
    define_error(:InvalidVolumeState, 400, '140')
  end
end
