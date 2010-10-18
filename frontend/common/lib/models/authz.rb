# -*- coding: utf-8 -*-
module Frontend::Models
  class Authz < BaseNew
    with_timestamps

    inheritable_schema do
      Fixnum :account_id, :null=>false
      index :account_id
      Fixnum :user_id, :null=>false
      index :user_id
      Fixnum :type_id, :null=>false
    end
    
    class << self
      def get_my_authz(user_id,account_id)
        self.dataset.where(:user_id => user_id,:account_id => account_id).all
      end
    end
  end

  module Tags
    class Authz < Tag
      def self.define_authz(klass_name, &blk)
        c = Class.new(Authz, &blk)
        @authz_collections ||= {}
        @authz_collections.store(c.type_id,klass_name)
        self.const_set(klass_name.to_sym, c)
      end
      
      def self.authz_collections
        @authz_collections
      end

      def accept_mapping?(taggable_obj)
        taggable_obj.is_a?(Models::User) && !taggable_obj.accounts_dataset.filter(:account_id=>self.account_id).empty?
      end

      def self.authz_evaluate?(authz_class)
        unless authz_class < Authz
          raise ArgumentError, "Can't compare the class does not have the root with #{self}"
        end
        authz_class == self
      end

      def after_initialize
        super
        # Set default name for the :name column.
        self[:name] = self.class.to_s.sub(/^Frontend::Models::Tags::/, '')
      end
    end
    
    Authz.define_authz(:ModifyAccount) do
      type_id 90001
      description ' modify priviledg'
      
      def self.authz_evaluate?(authz_class)
        super || [Authz::CreateAccount,Authz::DeleteAccount].any?{|klass| klass == authz_class}
      end
    end
  
    Authz.define_authz(:CreateAccount) do
      type_id 90002
      description ''
    end

    Authz.define_authz(:DeleteAccount) do
      type_id 90003
      description ''
    end
  
    Authz.define_authz(:AccountAdministrator) do
      type_id 90004
      description ''
    end
  
    Authz.define_authz(:ModifyUser) do
      type_id 90005
      description ''
    end

    Authz.define_authz(:ViewUser) do
      type_id 90006
      description ''
    end

    Authz.define_authz(:UserAdministrator) do
      type_id 90007
      description ''
    end
    
    Authz.define_authz(:AdminInstance) do
      type_id 90008
      description ''

      def self.authz_evaluate?(authz_class)
        super || [Authz::RunInstance].any?{|klass| klass == authz_class}
      end
    end
    
    Authz.define_authz(:RunInstance) do
      type_id 90009
      description ''
    end
  end
end