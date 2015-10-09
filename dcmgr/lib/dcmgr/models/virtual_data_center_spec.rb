# -*- coding: utf-8 -*-

module Dcmgr::Models
  class VirtualDataCenterSpec < BaseNew
    class YamlLoadError < StandardError; end
    class YamlFormatError < StandardError; end

    taggable 'vdcs'

    plugin :serialization

    serialize_attributes :yaml, :file

    subset(:alives, {:deleted_at => nil})

    def validate
      super

      f = self.file

      %w(vdc_name vdc_spec instance_spec).each do |param|
        errors.add(:file, "Undefined requried parameter: #{param}") if f[param].nil?

        next if param == 'vdc_name'

        if f[param] && !f[param].is_a?(Hash)
          errors.add(:file, "Invalid required parameter: #{param}") if !f[param].is_a?(Hash)
        end
      end

      if f['ssh_key_id']
        errors.add(:file, "Unknown ssh key: #{f['ssh_key_id']}") if !ssh_key_pair?(f['ssh_key_id'])
      end

      if f['vifs']
        begin
          Dcmgr::Scheduler::Network.check_vifs_parameter_format(f['vifs'])
        rescue
          errors.add(:file, "Invalid parameter: #{f['vifs']}")
        end
      end

      return if errors.length > 0

      f['instance_spec'].each do |k, v|
        %w(cpu_cores memory_size host_node_group hypervisor).each do |param|
          errros.add(:file, "Undefined requried parameter: instance_spec[#{k}][#{param}]") if v[param].nil?
        end

        if v['cpu_cores']
          if v['cpu_cores'] <= 0
            errors.add(:file, "It can not be less than zero: instance_spec[#{k}]['cpu_cores']")
          end
        end

        if v['memory_size']
          if v['memory_size'] <= 0
            errors.add(:file, "It can not be less than zero: instance_spec[#{k}]['memory_size']")
          end
        end

        if v['host_node_group']
          if !host_node_group?(v['host_node_group'])
            errors.add(:file, "Unknown host node group: instance_spec[#{k}]['host_node_group']")
          end
        end

        if v['hypervisor']
          if M::HostNode.online_nodes.filter(:hypervisor=>v['hypervisor']).empty?
            errors.add(:file, "Unknown/Inactive hypervisor: instance_spec[#{k}]['hypervisor']")
          end
        end

        if v['quota_weight']
          if v['quota_weight'] <= 0
            errors.add(:file, "It can not be less than zero: instance_spec[#{k}]['quota_weight']")
          end
        end
      end

      f['vdc_spec'].each do |k, v|
        %w(instance_spec image_id).each do |param|
          if v[param].nil?
            errors.add(:file, "Undefined requried parameter: vdc_spec[#{k}][#{param}]")
          end
        end

        if v['instance_spec']
          if !f['instance_spec'].keys.member?(v['instance_spec'])
            errors.add(:file, "Unknown instance spec: vdc_spec[#{k}]['instance_spec']")
          end
        end

        if v['image_id']
          if !images?(v['image_id'])
            errors.add(:file, "Unknown image id: vdc_spec[#{k}]['image_id']")
          end
        end

        if v['ssh_key_id']
          if !ssh_key_pair?(v['ssh_key_id'])
            errors.add(:file, "Unknown ssh key: #{v['ssh_key_id']}")
          end
        end

        if v['vifs']
          begin
            Dcmgr::Scheduler::Network.check_vifs_parameter_format(v['vifs'])
          rescue
            errors.add(:file, "Invalid parameter: #{v['vifs']}")
          end
        end

        if f['ssh_key_id'].nil? && v['ssh_key_id'].nil?
          errors.add(:file, "Undefinded parameter ssh_key_id")
        end

        if f['vifs'].nil? && v['vifs'].nil?
          errors.add(:file, "Undefinded parameter vifs")
        end
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
      vdc_spec = begin
                   YAML.load(spec_file)
                 rescue Psych::SyntaxError
                   raise YamlLoadError, 'The spec_file parameter must be a yaml format.'
                 end

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
          'ssh_key_id' => v['ssh_key_id'],
          'vifs' => v['vifs'],
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

    def ssh_key_pair?(ssh_key_id)
      ssh_key_id = SshKeyPair.dataset.alives.filter(:uuid=>SshKeyPair.trim_uuid(ssh_key_id)).first
      ssh_key_id.nil? ? false : true
    end

    def host_node_group?(tag_id)
      host_node_group = Dcmgr::Tags::HostNodeGroup[tag_id]
      host_node_group.nil? ? false : true
    end

    def images?(image_id)
      image = Image.dataset.alives.filter(:uuid=>Image.trim_uuid(image_id)).first
      image.nil? ? false : true
    end
  end
end
