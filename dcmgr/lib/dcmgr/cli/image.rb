# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Image < Base
    namespace :image
    M = Dcmgr::Models

    desc "add [options]", "Create a new machine image."
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine image."
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account that this machine image belongs to."
    method_option :boot_dev_type, :type => :numeric, :aliases => "-b", :desc => "The boot dev type for the new machine image."
    method_option :source, :type => :string, :aliases => "-so", :desc => "The source for the new machine image. Possible values: http, volume"
    method_option :uri, :type => :string, :desc => "The URI in case source is 'http'."
    method_option :snapshot_id, :type=> :string, :aliases => "-v", :desc => "The UUID for the snapshot to use in case source is 'volume'."
    method_option :arch, :type => :string, :desc => "The architecture for the new machine image."
    method_option :is_public, :type => :boolean, :aliases => "-p", :desc => "A flag that determines whether the new machine image is public or not."
    method_option :state, :type => :string, :aliases => "-st", :default => "init", :desc => "The state for the new machine image."
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      #TODO: Check if :state is a valid state
      fields = options.dup
      fields.delete(:uri)
      fields.delete(:volume)
      fields[:source] = case options[:source]
        when "http"
          {:type => :http,:uri => options[:uri]}
        when "volume"
          snp = M::VolumeSnapshot[options[:snapshot_id]]
          UnknownUUIDError.raise(options[:snapshot_id]) if snp.nil?
          {:type => :volume,:account_id => snp.account_id,:snapshot_id=>snp.canonical_uuid}
        else
          Error.raise("Source needs to be either 'http' or 'volume'.",100)
      end
      
      puts super(M::Image,fields)
    end
  end
end
