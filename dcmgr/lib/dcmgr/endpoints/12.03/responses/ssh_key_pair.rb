# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class SshKeyPair < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ssh_key_pair, private_key=nil)
      raise ArgumentError if !ssh_key_pair.is_a?(Dcmgr::Models::SshKeyPair)
      @ssh_key_pair = ssh_key_pair
      # @private_key is set when the user wants not to save it to database.
      @private_key = private_key
    end

    def generate()
      h = @ssh_key_pair.instance_exec {
        to_hash.merge(:id=>canonical_uuid, :labels=>resource_labels.map{ |l| ResourceLabel.new(l).generate })
      }
      h[:private_key] = @private_key if @private_key
      h
    end
  end

  class SshKeyPairCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        SshKeyPair.new(i).generate
      }
    end
  end
end
