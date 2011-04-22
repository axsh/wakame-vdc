# -*- coding: utf-8 -*-

require 'thor'

module Dcmgr::Cli
  class Base < Thor
    protected
    def self.basename
      "#{super()} #{namespace}"
    end

    no_tasks {
      public
      # add before/after task hook.
      def invoke_task(task, *args)
        before_task
        super(task, *args)
        after_task
      end
    
      protected
      def before_task
      end
      
      def after_task
      end
    }
  
  end
end
