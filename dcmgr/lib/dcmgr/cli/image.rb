# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Image < Base
    namespace :image
    M = Dcmgr::Models


    class AddOperation < Base
      namespace :add

      desc "local IMAGE_LOCATION [options]", "Register local store machine image"
      method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine image"
      method_option :account_id, :type => :string, :aliases => "-a", :required => true, :desc => "The UUID of the account that this machine image belongs to"
      method_option :arch, :type => :string, :default => 'x86_64', :aliases => "-r", :desc => "The architecture for the new machine image. [#{M::HostNode::SUPPORTED_ARCH.join(', ')}]"
      method_option :is_public, :type => :boolean, :aliases => "-p", :default => false, :desc => "A flag that determines whether the new machine image is public or not"
      method_option :md5sum, :type => :string, :aliases => "-m", :required => true, :desc => "The md5sum of the image you are registering."
      method_option :description, :type => :string, :aliases => "-d", :desc => "An arbitrary description of the new machine image"
      #method_option :state, :type => :string, :aliases => "-s", :default => "init", :desc => "The state for the new machine image"
      def local(location)
        UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
        UnsupportedArchError.raise(options[:arch]) unless M::HostNode::SUPPORTED_ARCH.member?(options[:arch])
        
        full_path = File.expand_path(location)
        File.exists?(full_path) || Error.raise("File not found: #{full_path}",100)
        
        #TODO: Check if :state is a valid state
        fields = options.dup
        fields[:boot_dev_type]=M::Image::BOOT_DEV_LOCAL
        fields[:source] = {
          :uri => "file://#{full_path}",
        }
        puts add(M::Image, fields)
      end

      desc "volume snapshot_id [options]", "Register volume store machine image."
      method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine image."
      method_option :account_id, :type => :string, :aliases => "-a", :required => true, :desc => "The UUID of the account that this machine image belongs to."
      method_option :arch, :type => :string, :default => 'x86_64', :aliases => "-r", :desc => "The architecture for the new machine image. [#{M::HostNode::SUPPORTED_ARCH.join(', ')}]"
      method_option :is_public, :type => :boolean, :aliases => "-p", :default => false, :desc => "A flag that determines whether the new machine image is public or not."
      method_option :md5sum, :type => :string, :aliases => "-m", :required => true, :desc => "The md5sum of the image you are registering."
      method_option :description, :type => :string, :aliases => "-d", :desc => "An arbitrary description of the new machine image"
      #method_option :state, :type => :string, :aliases => "-s", :default => "init", :desc => "The state for the new machine image"
      def volume(snapshot_id)
        UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
        UnsupportedArchError.raise(options[:arch]) unless M::HostNode::SUPPORTED_ARCH.member?(options[:arch])
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

    desc "modify UUID [options]", "Modify a registered machine image"
    method_option :description, :type => :string, :aliases => "-d", :desc => "An arbitrary description of the machine image"
    method_option :state, :type => :string, :aliases => "-s", :default => "init", :desc => "The state for the machine image"
    def modify(uuid)
      #TODO: Check if state is valid here too
      super(M::Image,uuid,options)
    end

    desc "del IMAGE_ID", "Delete registered machine image"
    def del(image_id)
      UnknownUUIDError.raise(image_id) if M::Image[image_id].nil?
      super(M::Image, image_id)
    end

    desc "show [IMAGE_ID]", "Show list of machine image and details"
    def show(uuid=nil)
      if uuid
        img = M::Image[uuid] || UnknownUUIDError.raise(uuid)
        print ERB.new(<<__END, nil, '-').result(binding)
UUID:
  <%= img.canonical_uuid %>
Boot Type:
  <%= img.boot_dev_type == M::Image::BOOT_DEV_LOCAL ? 'local' : 'volume'%>
Arch:
  <%= img.arch %>
<%- if img.description -%>
MD5 Sum:
  <%= img.md5sum %>
Description:
  <%= img.description %>
<%- end -%>
Is Public:
  <%= img.is_public %>
State:
  <%= img.state %>
__END
      else
        cond = {}
        imgs = M::Image.filter(cond).all
        print ERB.new(<<__END, nil, '-').result(binding)
<%- imgs.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.boot_dev_type == M::Image::BOOT_DEV_LOCAL ? 'local' : 'volume'%>\t<%= row.arch %>
<%- } -%>
__END
      end
    end
  end
end
