# -*- coding: utf-8 -*-

require 'forwardable'

module Dcmgr::Helpers
  module Cgroup
    module CgroupContextProvider
      CGROUP_CTX_STACK_KEY='cgroup_ctx_stack'.freeze
      
      class CgroupContext
        attr :subsystems
        attr :scope
        
        def initialize(subsystems=[], scope)
          @subsystems = subsystems.is_a?(Array) ? subsystems : [subsystems]
          @scope = scope
        end
      end

      @delegate_methods = []
      def self.delegate_methods
        @delegate_methods
      end

      module Delegator
        include CgroupContextProvider
        private
        def self.included(klass)
          klass.extend Forwardable unless klass < Forwardable
          klass.def_delegators(:@cgprovider, *CgroupContextProvider.delegate_methods)
        end
      end
      
      def cgroup_context_stack
        # task_session() is supplied by Task::Tasklet's derivertives.
        task_session[CGROUP_CTX_STACK_KEY] ||= []
      end
      delegate_methods << :cgroup_context_stack
      
      def current_cgroup_context
        cgroup_context_stack.first
      end
      delegate_methods << :current_cgroup_context

      def self.included(klass)
        unless klass < Dcmgr::Task::Tasklet
          raise TypeError, "Can not attach to #{klass}: method from Task::Tasklet is needed for #{self}"
        end
      end
      
      # 
      # cgroup_context(:subsystem=>'blkio') do
      #   # "ls" is executed under the cgroup namespace.
      #   sh("/bin/ls")
      #
      #   # can be nested.
      #   cgroup_context() do
      #   end
      # end
      def cgroup_context(ctx=current_cgroup_context, &blk)
        ctx = CgroupContext.new(ctx[:subsystem], ctx[:scope]) if ctx.is_a?(Hash)
        
        cgroup_context_stack.push(ctx)
        begin
          blk.call
        ensure
          cgroup_context_stack.pop
        end
      end
    end
    
  end
end
