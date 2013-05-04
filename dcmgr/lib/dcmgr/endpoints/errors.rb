# -*- coding: utf-8 -*-

module Dcmgr
  module Endpoints
    module Errors
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
        # Sinatra reads http code from this method.
        alias :code :status_code
        alias :http_status :status_code

        def error_code
          self.class.error_code
        end
      end

      class DeprecatedAPIError < APIError
      end
    end

    def self.define_error(class_name, status_code, error_code, &blk)
      c = Class.new(Errors::APIError)
      c.status_code(status_code)
      c.error_code(error_code)
      c.instance_eval(&blk) if blk
      self.set_error_code_type(error_code, c)
      self.const_set(class_name.to_sym, c)
      Errors.const_set(class_name.to_sym, c)
    end

    def self.deprecated_error(class_name, status_code, error_code, &blk)
      c = Class.new(Errors::DeprecatedAPIError)
      c.status_code(status_code)
      c.error_code(error_code)
      c.instance_eval(&blk) if blk
      self.set_error_code_type(error_code, c)
      self.const_set(class_name.to_sym, c)
      Errors.const_set(class_name.to_sym, c)
    end

    @error_code_map = {}
    def self.set_error_code_type(error_code, klass)
      raise TypeError unless klass < Errors::APIError
      if @error_code_map.has_key?(error_code)
        if @error_code[error_code] == klass
        else
          raise "Duplicate Error Code Registration: #{klass}, code=#{error_code}"
        end
      else
        @error_code_map[error_code]=klass
      end
    end

    define_error(:UnknownUUIDResource, 404, '100')
    define_error(:UnknownMember, 400, '101')
    define_error(:InvalidCredentialHeaders, 400, '102')
    define_error(:InvalidRequestCredentials, 400, '103')
    define_error(:DisabledAccount, 403, '104')
    define_error(:OperationNotPermitted, 403, '105')
    define_error(:UndefinedVolumeSize, 400, '106')
    define_error(:StorageNodeNotPermitted, 403, '107')
    define_error(:UnknownStorageNode, 404, '108')
    define_error(:OutOfDiskSpace, 400, '109')
    define_error(:DatabaseError, 400, '110')
    define_error(:UndefinedVolumeID, 400, '111')
    define_error(:InvalidDeleteRequest, 400, '112')
    define_error(:UnknownVolume, 404, '113')
    define_error(:UnknownHostNode, 404, '114')
    define_error(:UnknownInstance, 404, '115')
    define_error(:UndefindVolumeSnapshotID, 400, '116')
    define_error(:UnknownVolumeSnapshot, 404, '117')
    define_error(:UndefinedRequiredParameter, 400, '118')
    define_error(:InvalidVolumeSize, 400, '119')
    define_error(:OutOfHostCapacity, 400, '120')
    define_error(:UnknownSshKeyPair, 404, '121')
    define_error(:UndefinedStorageNodeID, 400, '122')
    define_error(:DetachVolumeFailure, 400, '123')
    define_error(:AttachVolumeFailure, 400, '124')
    define_error(:InvalidInstanceState, 400, '125')
    define_error(:DuplicateHostname, 400, '126')
    define_error(:UnknownImage, 404, '127')
    define_error(:UnknownInstanceSpec, 404, '128')
    define_error(:UnknownNetwork, 404, '129')
    define_error(:OutOfNetworkCapacity, 400, '130')
    define_error(:InvalidVolumeSnapshotState, 400, '131')

    define_error(:UndefinedSecurityGroup, 404, '132')
    define_error(:UnknownSecurityGroup, 404, '133')
    define_error(:SecurityGroupNotPermitted, 400, '134')
    deprecated_error(:DuplicatedSecurityGroup, 400, '135')

    define_error(:DuplicateSshKeyName, 400, '136')
    define_error(:InvalidImageID, 400, '137')
    define_error(:InvalidInstanceSpec, 400, '138')
    define_error(:UndefinedInstanceID, 404, '139')
    define_error(:InvalidVolumeState, 400, '140')
    define_error(:InvalidHostNodeID, 400, '141')
    define_error(:InvalidSecurityGroupRule, 400, '142')
    define_error(:InvalidParameter, 400, '143')
    define_error(:UnknownNetworkVif, 404, '144')
    define_error(:NetworkVifAlreadyAttached, 500, '145')
    define_error(:NetworkVifNicNotFound, 500, '146')
    define_error(:NetworkVifNotAttached, 500, '147')
    define_error(:UndefinedNetworkID, 404, '148')
    define_error(:UndefinedLoadBalancerID, 404, '149')
    define_error(:UnknowLoadBalancerID, 404, '150')
    define_error(:DuplicateNetworkVif, 400, '151')
    define_error(:UndefinedImageID, 404, '152')

    define_error(:UnknownBackupStorage, 404, '153')
    define_error(:DestroyedUUIDResource, 404, '154')
    define_error(:UndefinedBackupObject, 404, '155')
    define_error(:UnknownBackupObject, 404, '156')
    define_error(:InvalidBackupObjectState, 500, '157')
    define_error(:ExistsRegisteredInstance, 400, '158')
    define_error(:InvalidLoadBalancerState, 400, '159')
    define_error(:InvalidLoadBalancerPort, 400, '160')
    define_error(:InvalidLoadBalancerAlgorithm, 400, '161')

    define_error(:ExceedQuotaLimit, 400, '162')
    define_error(:UnknownDcNetwork, 404, '163')
    define_error(:NetworkNotPermitted, 400, '164')
    define_error(:DcNetworkNotPermitted, 400, '165')
    define_error(:InvalidLoadBalancerPrivateKey, 400, '166')
    define_error(:InvalidLoadBalancerPublicKey, 400, '167')
    define_error(:EncryptionAlgorithmNotSupported, 400, '168')

    define_error(:NetworkInvalidAddress, 500, '169')
    define_error(:NetworkVifInvalidAddress, 500, '170')
    define_error(:MessagingFailed, 500, '171')
    define_error(:UnknownNetworkService, 404, '172')
    define_error(:InvalidSshPublicKey, 400, '173')

    define_error(:InvalidMacAddress, 400, '174')
    define_error(:DuplicateMacAddress, 400, '175')
    define_error(:InvalidIPAddress, 400, '176')
    define_error(:DuplicateIPAddress, 400, '177')
    define_error(:IPAddressNotInSegment, 400, '178')
    define_error(:IncompatibleHostNode, 400, '179')
    define_error(:MacNotInRange, 400, '180')
    define_error(:IpNotInDhcpRange, 400, '181')
    define_error(:InvalidBackupStorage, 400, '182')
    define_error(:UnknownIpHandle, 404, '183')
    define_error(:UnknownIpPool, 404, '184')
    define_error(:IpHandleInUse, 404, '185')
    define_error(:InvalidLoadBalancerAllowList, 400, '186')
    define_error(:UnknownResourceLabel, 404, '187')
    define_error(:InvalidLoadBalancerProtocol, 400, '188')
    define_error(:InvalidLoadBalancerHttpChkPath, 400, '189')
    define_error(:NetworkNotInDcNetwork, 404, '190')
    define_error(:LoadBalancerNotPermitted, 404, '191')
    define_error(:InvalidLoadBalancerInstancePort, 404, '192')
    define_error(:InvalidLoadBalancerInstanceProtocol, 404, '193')
    define_error(:DuplicateLoadBalancerPort, 400, '194')
    define_error(:InvalidLoadBalancerSpec, 400, '195')

  end
end
