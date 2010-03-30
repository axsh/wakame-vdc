require 'digest/sha1'

module Dcmgr
  class RoleError < StandardError; end
    
  module RoleExecutor
    class Base
      include Dcmgr::Models

      @@inherited_classes = []

      def self.inherited(subclass)
        # check duplicate class name for generate class name hash
        if @@inherited_classes.index(subclass)
          raise "Deplicated class #{subclass.name}"
        end

        @@inherited_classes << subclass
      end
    
      def initialize(target, params)
        @target = target
        @params = params
      end

      def self.id
        if @cached_id
          @cached_id
        end
        @cached_id = generate_id
      end

      def self.generate_id
        Digest::SHA1.hexdigest(self.name)[0,8]
      end

      def self.roles
        @@inherited_classes.select{|c|
          c.allow_types != nil
        }
      end

      def self.allow_types; @allow_types; end

      def class_target?
        @target.class == Class
      end

      def evaluate(account, evaluator)
        Models::Tag.join(:tag_attributes,
                         :tag_id=>:id).
          filter(:owner_id=>evaluator.id,
                 :tag_attributes__role=>self.class.id,
                 :account_id=>account.id).each{|tag|
          unless class_target?
            return true if @target.tags.index{|t| tag.tags.include? t}
          end
          
          return true if TagMapping.dataset.where(:target_type=>
                                                  self.class.allow_types,
                                                  :tag_id=>tag.tags.map{|t| t.id},
                                                  :target_id=>0).count > 0
        }
        raise RoleError, "no role #{self.class}" +
          "(user: #{evaluator.uuid}, account: #{account.uuid}, target: #{@target})"
      end

      def execute(account, evaluator)
        evaluate(account, evaluator)
        _execute(account, evaluator, @target)
      end

      attr_reader :params
    end
    
    class CreateAction < Base
      def _execute(accont, user, target)
        target.save
        true
      end
    end

    class DestroyAction < Base
      def _execute(accont, user, target)
        target.destroy
        true
      end
    end

    class RunInstance < Base
      @allow_types = [TagMapping::TYPE_INSTANCE]
      
      def _execute(account, user, instance)
        instance.status = Instance::STATUS_TYPE_ONLINE
        instance.save
        true
      end
    end

    class ShutdownInstance < Base
      @allow_types = [TagMapping::TYPE_INSTANCE]

      private
      def _execute(account, user, instance)
        instance.status = Instance::STATUS_TYPE_OFFLINE
        instance.save
        true
      end
    end

    class CreateAccount < CreateAction;
      @allow_types = [TagMapping::TYPE_ACCOUNT]
    end

    class DestroyAccount < DestroyAction
      @allow_types = [TagMapping::TYPE_ACCOUNT]
    end

    class CreateImageStorage < CreateAction
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE]
    end

    class GetImageStorage < Base
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE]

      private
      def _execute(account, user, image_storage_class)
        ImageStorage[params]
      end
    end

    class DestroyImageStorage < DestroyAction
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE]
    end

    class CreateImageStorageHost < CreateAction
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE_HOST]
    end

    class DestroyImageStorageHost < DestroyAction
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE_HOST]
    end

    class CreatePhysicalHost < CreateAction
      @allow_types = [TagMapping::TYPE_PHYSICAL_HOST]
    end

    class DestroyPhysicalHost < DestroyAction
      @allow_types = [TagMapping::TYPE_PHYSICAL_HOST]
    end

    class CreateHvController < CreateAction
      @allow_types = [TagMapping::TYPE_HV_CONTROLLER]
    end

    class DestroyHvController < DestroyAction
      @allow_types = [TagMapping::TYPE_HV_CONTROLLER]
    end

    class CreateHvAgent < CreateAction
      @allow_types = [TagMapping::TYPE_HV_AGENT]
    end

    class DestroyHvAgent < DestroyAction
      @allow_types = [TagMapping::TYPE_HV_AGENT]
    end

    def self.roles
      Base.roles
    end

    def self.get(target, action, params={})
      rolename = if target.class == Class
                 then "%s%s" % [action.to_s.capitalize,
                                target.name.split(/::/).last]
                 else "%s%s" % [action.to_s.capitalize,
                                target.class.to_s.split(/::/).last]
                 end
      begin
        roleclass = eval("%s" % rolename)
      rescue NameError
        Dcmgr::logger.debug "unmatch role name: #{rolename}"
        return nil
      end
      return nil unless roles.include? roleclass
      roleclass.new(target, params)
    end
  end

  # auth target is image or user
  def self.evaluate(evaluator, target, action)
    raise ArgumentError.new("unknown class: %s" % evaluator) unless evaluator.is_a?(User)
    
    role = RoleExecutor.get(target, action)
    raise ArgumentError.new("unkown role(target: %s, action: %s)" % [target, action]) unless role
    
    Dcmgr::logger.debug("role: %s" % role)
    role.evaluate(evaluator, target)
    role.execute(evaluator, target)
  end
end
