
module Dcmgr
  class RoleError < StandardError; end
    
  module RoleExecutor
    class Base
      include Dcmgr::Models
    
      def initialize(target, params)
        @target = target
        @params = params
      end

      def self.id; @id; end

      def self.allow_types; @allow_types; end

      def class_target?
        @target.class == Class
      end

      def evaluate(account, evaluator)
        Tag.join(:tag_attributes,
                 :tag_id=>:id).filter(:owner_id=>evaluator.id,
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
      @id = 1
      @allow_types = [TagMapping::TYPE_INSTANCE]
      
      def _execute(account, user, instance)
        instance.status = Instance::STATUS_TYPE_ONLINE
        instance.save
        true
      end
    end

    class ShutdownInstance < Base
      @id = 2
      @allow_types = [TagMapping::TYPE_INSTANCE]

      private
      def _execute(account, user, instance)
        instance.status = Instance::STATUS_TYPE_OFFLINE
        instance.save
        true
      end
    end

    class CreateAccount < CreateAction;
      @id = 3
      @allow_types = [TagMapping::TYPE_ACCOUNT]
    end

    class DestroyAccount < DestroyAction
      @id = 4
      @allow_types = [TagMapping::TYPE_ACCOUNT]
    end

    class CreateImageStorage < CreateAction
      @id = 5
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE]
    end

    class GetImageStorage < Base
      @id = 6
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE]

      private
      def _execute(account, user, image_storage_class)
        ImageStorage[params]
      end
    end

    class DestroyImageStorage < DestroyAction
      @id = 7
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE]
    end

    class CreateImageStorageHost < CreateAction
      @id = 8
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE_HOST]
    end

    class DestroyImageStorageHost < DestroyAction
      @id = 9
      @allow_types = [TagMapping::TYPE_IMAGE_STORAGE_HOST]
    end

    class CreatePhysicalHost < CreateAction
      @id = 10
      @allow_types = [TagMapping::TYPE_PHYSICAL_HOST]
    end

    class DestroyPhysicalHost < DestroyAction
      @id = 11
      @allow_types = [TagMapping::TYPE_PHYSICAL_HOST]
    end

    class CreateHvController < CreateAction
      @id = 12
      @allow_types = [TagMapping::TYPE_HV_CONTROLLER]
    end

    class DestroyHvController < DestroyAction
      @id = 13
      @allow_types = [TagMapping::TYPE_HV_CONTROLLER]
    end

    class CreateHvAgent < CreateAction
      @id = 14
      @allow_types = [TagMapping::TYPE_HV_AGENT]
    end

    class DestroyHvAgent < DestroyAction
      @id = 15
      @allow_types = [TagMapping::TYPE_HV_AGENT]
    end

    @roles = [RunInstance,
              ShutdownInstance,
              CreateAccount,
              DestroyAccount,
              CreateImageStorage,
              GetImageStorage,
              DestroyImageStorage,
              CreateImageStorageHost,
              DestroyImageStorageHost,
              CreatePhysicalHost,
              DestroyPhysicalHost,
              CreateHvController,
              DestroyHvController,
              CreateHvAgent,
              DestroyHvAgent,
             ]

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
      return nil unless @roles.include? roleclass
      roleclass.new(target, params)
    end

    def self.roles
      @roles
    end
  end

  # auth target is image or user
  def self.evaluate(evaluator, target, action)
    raise ArgumentError.new("unknown class: %s" % evaluator) unless evaluator.is_a?(User)
    
    role = RoleExecutor[target, action]
    raise ArgumentError.new("unkown role(target: %s, action: %s)" % [target, action]) unless role
    
    Dcmgr::logger.debug("role: %s" % role)
    role.evaluate(evaluator)
    
    role.execute(evaluator)
  end
end
