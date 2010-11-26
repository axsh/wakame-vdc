# -*- coding: utf-8 -*-

module Dcmgr
  module Endpoints
    def self.define_error(class_name, status_code, &blk)
      c = Class.new(APIError)
      c.status_code(status_code)
      c.instance_eval(&blk) if blk
      self.const_set(class_name.to_sym, c)
    end

    class APIError < StandardError
      def self.status_code(code=nil)
        if code
          @status_code = code
        end
        @status_code || raise("@status_code for the class is not set")
      end

      def status_code
        self.class.status_code
      end
    end

    define_error(:UnknownUUIDResource, 404)
    define_error(:UnknownMember, 400)
    define_error(:InvalidCredentialHeaders, 400)
    define_error(:InvalidRequestCredentials, 400)
    define_error(:DisabledAccount, 403)
    define_error(:OperationNotPermitted, 403)
    define_error(:UndefinedVolumeSize, 400)
    define_error(:StoragePoolNotPermitted, 403)
    define_error(:UnknownStoragePool, 404)
    define_error(:OutOfDiskSpace, 400)
    define_error(:DatabaseError, 400)
    define_error(:UndefinedVolumeID, 400)
    define_error(:InvalidDeleteRequest, 400)
    define_error(:UnknownVolume, 404)
    define_error(:UnknownHostPool, 404)
    define_error(:UnknownInstance, 404)
    define_error(:UndefindVolumeSnapshotID, 400)
    define_error(:UnknownVolumeSnapshot, 404)
    define_error(:UndefinedRequiredParameter, 400)
    define_error(:InvalidVolumeSize, 400)
    define_error(:OutOfHostCapacity, 400)
    define_error(:UnknownSshKeyPair, 404)
    define_error(:UndefinedStoragePoolID, 400)
    define_error(:DetachVolumeFailure, 400)

    # netfilter_group
    define_error(:UndefinedNetfilterGroup, 400)
    define_error(:UnknownNetfilterGroup, 400)
    define_error(:NetfilterGroupNotPermitted, 400)
    define_error(:DuplicatedNetfilterGroup, 400)
  end
end
