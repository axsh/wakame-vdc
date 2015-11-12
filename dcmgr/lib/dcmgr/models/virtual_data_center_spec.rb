# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VirtualDataCenterSpec < BaseNew
    class YamlLoadError < StandardError; end
    class YamlFormatError < StandardError; end

    taggable 'vdcs'

    plugin :serialization

    serialize_attributes :yaml, :file

    subset(:alives, {:deleted_at => nil})

    include Dcmgr::Constants::VirtualDataCenterSpec

    def validate
      super

      f = self.file

      validates_required_params_include(VDCS_PARAMS, file)
      validates_params_type(String, file[VDCS_PARAMS_STRING])
      VDCS_PARAMS_HASH.each do |param|
        validates_params_type(Hash, file[param])
      end

      if file['ssh_key_id']
        validates_ssh_key(file['ssh_key_id'])
      end

      if file['vifs']
        validates_vifs(file['vifs'])
      end

      return if errors.length > 0

      file['instance_spec'].each do |k, v|
        validates_required_params_include(VDCS_INSTANCE_PARAMS, v)
        VDCS_INSTANCE_PARAMS_STRING.each do |param|
          validates_params_type(String, v[param])
        end
        VDCS_INSTANCE_PARAMS_INT.each do |param|
          validates_params_type(Integer, v[param])
          if v[param]
            validates_params_min_length(v[param])
          end
        end

        if v['host_node_group']
          validates_host_node_group(v['host_node_group'])
        end

        if v['hypervisor']
          validates_hypervisor(v['hypervisor'])
        end

        if v['quota_weight']
          validates_params_type(Numeric, v['quota_weight'])
          validates_params_min_length(v['quota_weight'])
        end
      end

      return if errors.length > 0

      f['vdc_spec'].each do |k, v|
        validates_required_params_include(VDCS_SPEC_PARAMS, v)
        VDCS_SPEC_PARAMS.each do |param|
          validates_params_type(String, v[param])
        end

        if v['instance_spec']
          validates_instance_spec(v['instance_spec'])
        end

        if v['image_id']
          validates_image(v['image_id'])
        end

        if v['ssh_key_id']
          validates_ssh_key(v['ssh_key_id'])
        end

        if v['vifs']
          validates_vifs(v['vifs'])
        end
      end

    end

    def validates_required_params_include(params, file)
      params.each do |param|
        errors.add(:file, "Undefined requried parameter: #{param}") if file[param].blank?
      end
    end

    def validates_params_type(type, param)
      errors.add(:file, "Invalid required parameter: #{param}") if !param.is_a?(type)
    end

    def validates_params_min_length(param)
      errors.add(:file, "It can not be less than zero: #{param}") if param.to_i <= 0
    end

    def validates_ssh_key(ssh_key_id)
      errors.add(:file, "Unknown ssh key: #{ssh_key_id}") if !check_ssh_key(ssh_key_id)
    end

    def validates_vifs(vifs)
      begin
        Dcmgr::Scheduler::Network.check_vifs_parameter_format(vifs)
      rescue
        errors.add(:file, "Invalid parameter: #{vifs}")
      end
    end

    def validates_host_node_group(host_node_group)
      if !check_host_node_group(host_node_group)
        errors.add(:file, "Unknown host node group: #{host_node_group}")
      end
    end

    def validates_hypervisor(hypervisor)
      if M::HostNode.online_nodes.filter(:hypervisor=>hypervisor).empty?
        errors.add(:file, "Unknown/Inactive hypervisor: #{hypervisor}")
      end
    end

    def validates_instance_spec(instance_spec)
      if !file['instance_spec'].keys.member?(instance_spec)
        errors.add(:file, "Unknown instance spec: #{instance_spec}")
      end
    end

    def validates_image(image_id)
      if !check_image(image_id)
        errors.add(:file, "Unknown image id: #{image_id}")
      end
    end

    def self.entry_new(account, &blk)
      argument_type_check(account, Account)

      vdcs = self.new &blk
      vdcs.account_id = account.canonical_uuid
      vdcs.save
      vdcs
    end

    def self.load(spec_file)
      argument_type_check(spec_file, String)

      vdc_spec = YAML.load(spec_file)

      vdc_spec
    end

    def instance_capacity
      specs = file['vdc_spec'].map { |k, v| v['instance_spec'] }.group_by { |t| t }
      specs.inject(0) { |sum, (k, v)|
        unless file['instance_spec'][k]['quota_weight'].nil?
          sum += (file['instance_spec'][k]['quota_weight'] * v.length )
        end
      }
    end

    def generate_instance_params
      instance_params = []
      self.file['vdc_spec'].each { |k, v|
        instance_params << {
          'image_id' => v['image_id'],
          'ssh_key_id' => v['ssh_key_id'] || self.file['ssh_key_id'],
          'vifs' => v['vifs'] || self.file['vifs'],
          'user_data' => YAML.dump(v['user_data']),
        }.merge(self.file['instance_spec'][v['instance_spec']])
      }

      instance_params
    end

    private
    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

    def check_ssh_key(ssh_key_id)
      ssh_key_id = SshKeyPair.dataset.alives.filter(:uuid=>SshKeyPair.trim_uuid(ssh_key_id)).first
      ssh_key_id.nil? ? false : true
    end

    def check_host_node_group(tag_id)
      host_node_group = Dcmgr::Tags::HostNodeGroup[tag_id]
      host_node_group.nil? ? false : true
    end

    def check_image(image_id)
      image = Image.dataset.alives.filter(:uuid=>Image.trim_uuid(image_id)).first
      image.nil? ? false : true
    end
  end
end
