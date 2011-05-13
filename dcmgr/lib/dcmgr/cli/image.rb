# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Image < Base
    namespace :image
    M = Dcmgr::Models


    class AddOperation < Base
      namespace :add

      desc "local URI [options]", "Register local store machine image."
      method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine image."
      method_option :account_id, :type => :string, :aliases => "-a", :required => true, :desc => "The UUID of the account that this machine image belongs to."
      method_option :arch, :type => :string, :default => 'x86_64', :desc => "The architecture for the new machine image. [#{M::HostPool::SUPPORTED_ARCH.join(', ')}]"
      method_option :is_public, :type => :boolean, :aliases => "-p", :default => false, :desc => "A flag that determines whether the new machine image is public or not."
      method_option :state, :type => :string, :aliases => "-st", :default => "init", :desc => "The state for the new machine image."
      def local(uri)
        UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
        UnsupportedArchError.raise(options[:arch]) unless M::HostPool::SUPPORTED_ARCH.member?(options[:arch])
        #TODO: Check if :state is a valid state
        fields = options.dup
        fields[:boot_dev_type]=M::Image::BOOT_DEV_LOCAL
        fields[:source] = {
          :uri => uri,
        }
        puts add(M::Image, fields)
      end

      desc "volume snapshot_id [options]", "Register volume store machine image."
      method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine image."
      method_option :account_id, :type => :string, :aliases => "-a", :required => true, :desc => "The UUID of the account that this machine image belongs to."
      method_option :arch, :type => :string, :default => 'x86_64', :desc => "The architecture for the new machine image. [#{M::HostPool::SUPPORTED_ARCH.join(', ')}]"
      method_option :is_public, :type => :boolean, :aliases => "-p", :default => false, :desc => "A flag that determines whether the new machine image is public or not."
      method_option :state, :type => :string, :aliases => "-st", :default => "init", :desc => "The state for the new machine image."
      def volume(snapshot_id)
        UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
        UnsupportedArchError.raise(options[:arch]) unless M::HostPool::SUPPORTED_ARCH.member?(options[:arch])
        UnknownUUIDError.raise(snapshot_id) if M::VolumeSnapshot[snapshot_id].nil?
        #TODO: Check if :state is a valid state
        fields = options.dup
        fields[:boot_dev_type]=M::Image::BOOT_DEV_SAN
        fields[:source] = {
          :snapshot_id => snapshot_id,
        }
        puts add(M::Image, fields)
      end
      
      protected
      def self.basename
        "vdc-manage #{Image.namespace} #{self.namespace}"
      end
    end

    register AddOperation, 'add', "add IMAGE_TYPE [options]", "Add image metadata [#{AddOperation.tasks.keys.join(', ')}]"

  end
end
