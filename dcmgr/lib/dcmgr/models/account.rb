# -*- coding: utf-8 -*-

module Dcmgr::Models
  class Account < BaseNew
    taggable 'a'
    # pk has to be overwritten by the STI subclasses.
    unrestrict_primary_key

    DISABLED=0
    ENABLED=1
    
    one_to_many  :tags, :dataset=>lambda { Tag.filter(:account_id=>self.canonical_uuid); }

    subset(:alives, {:deleted_at => nil})
    
    # sti plugin has to be loaded at lower position.
    plugin :subclasses
    plugin :single_table_inheritance, :uuid, :model_map=>{}
    

    def disable?
      self.enabled == DISABLED
    end

    def enable?
      self.enabled == ENABLED
    end
    
    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

    # STI class variable setter, getter methods.
    class << self
      def default_values
        @default_values ||= {}
      end

      def pk(pk=nil)
        if pk
          default_values[:id] = pk
        end
        default_values[:id]
      end
      
      def uuid(uuid=nil)
        if uuid.is_a?(String)
          uuid = uuid.downcase
          unless self.check_trimmed_uuid_format(uuid)
            raise "Invalid syntax of uuid: #{uuid}"
          end
          default_values[:uuid] = uuid
        end
        raise("#{self}.uuid is unset. Set the unique number") unless default_values[:uuid]
        "#{uuid_prefix}-#{default_values[:uuid]}"
      end

      def description(description=nil)
        if description
          default_values[:description] = description
        end
        default_values[:description]
      end
    end

    module SystemAccount
      def self.define_account(class_name, &blk)
        unless class_name.is_a?(Symbol) || class_name.is_a?(String)
          raise ArgumentError
        end

        c = Class.new(Account, &blk)
        self.const_set(class_name.to_sym, c)
        Account.sti_model_map[c.uuid] = c
        Account.sti_key_map[c.to_s] = c.uuid
        c
      end
    end

    install_data_hooks do
      Account.subclasses.each { |m|
        Account.create(m.default_values.dup)
      }

      # create shared resource pool tags
      Dcmgr::Tags::HostNodeGroup.create(:account_id=>SystemAccount::SharedPoolAccount.uuid,
                                   :uuid=>'shhost',
                                   :name=>"default_shared_hosts")
      Dcmgr::Tags::NetworkGroup.create(:account_id=>SystemAccount::SharedPoolAccount.uuid,
                                      :uuid=>'shnet',
                                      :name=>"default_shared_networks")
      Dcmgr::Tags::StorageNodeGroup.create(:account_id=>SystemAccount::SharedPoolAccount.uuid,
                                      :uuid=>'shstor',
                                      :name=>"default_shared_storages")
    end
    
    SystemAccount.define_account(:DatacenterAccount) do
      pk 100
      uuid '00000000'
      description 'datacenter system account'

      # DatacenterAccount never be disabled
      def before_save
        super
        self.enabled = Account::ENABLED
      end
    end

    SystemAccount.define_account(:SharedPoolAccount) do
      pk 101
      uuid 'shpoolxx'
      description 'system account for shared resources'

      # SahredPoolAccount is always enabled.
      def before_save
        super
        self.enabled = Account::ENABLED
      end
    end
    
  end
end

