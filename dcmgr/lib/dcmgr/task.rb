# -*- coding: utf-8 -*-

require 'fiber'

module Dcmgr
  module Task
    #
    # class TaskA < Tasklet
    #   before do
    #     @v += 1
    #   end
    #
    #   session_begin do
    #     session[:func3] = 1
    #   end
    #
    #   def initialize(v=10)
    #     @v = v
    #   end
    #
    #   def func1(a, b)
    #     puts @v
    #     puts a
    #     puts b
    #   end
    #
    #   def func2
    #     puts @v
    #   end
    #
    #   def func3
    #     puts session[:func3] += 1
    #   end
    # end
    #
    # class TaskB < Tasklet
    #   def initialize(path)
    #     @passwd = File.read(path)
    #   end
    #
    #   def func1
    #     invoke_task(TaskA, func1, [1, 2])
    #     puts "TaskB#func1"
    #   end
    #
    #   register(self.new('/etc/passwd'))
    # end
    #
    # TaskSession.reset!(:thread)
    #
    # # Create new TaskA object always.
    # TaskSession.invoke(TaskA, :func1, ['1', '2'])
    # # => 11
    # # => 1
    # # => 2
    #
    # # Create TaskA object once in earlier stage then call method of
    # # the object. So Tasklet#initialize can be used for loading conf files etc.
    # Tasklet.register(TaskA.new(20))
    #
    # TaskSession.invoke(TaskA, :func2)
    # # => 21
    # TaskSession.invoke(TaskA, :func2)
    # # => 21
    #
    # # Task session example.
    # TaskSession.invoke(TaskA, :func3)
    # # => 1
    # TaskSession.invoke(TaskA, :func3)
    # # => 2
    class Tasklet
      @registry = {}

      class << self
        def register(tasklet)
          raise ArgumentError unless tasklet.is_a?(Tasklet)
          @registry[tasklet.class] = tasklet
        end

        def registry
          @registry
        end

        attr_reader :task_hooks

        def reset!
          @task_hooks = {:before => [], :after => [], :session_begin => []}
        end

        def before(&blk)
          @task_hooks[:before] << blk
        end

        def after(&blk)
          @task_hooks[:after] << blk
        end

        def session_begin(&blk)
          @task_hooks[:session_begin] << blk
        end

        def helpers(*mods)
          mods.each {|i|
            include i
          }
        end

        private

        def inherited(klass)
          klass.reset!
        end
      end

      self.reset!

      def invoke(method, args=[])
        dup.invoke!((@task_session || TaskSession.current), method, args)
      end
      protected :invoke

      def invoke_task(taskclass, method, args=[])
        @task_session.invoke(taskclass, method, args)
      end
      protected :invoke_task

      def invoke_hook(type, args=[])
        invoke_hook!(type)
      end

      module Helpers
        def task_session
          @task_session
        end
        alias :session :task_session
      end

      helpers Helpers

      def invoke!(session, method, args=[])
        raise ArgumentError unless session.is_a?(TaskSession)
        raise "Unknown method: #{self.class}\##{method}" unless self.respond_to?(method)

        @task_session = session
        @method = method
        @args = args

        begin
          invoke_hook! :before
          # method must be public.
          self.send(method, *@args)
        ensure
          invoke_hook! :after
        end
      end

      def invoke_hook!(type, base=self.class)
        invoke_hook!(type, base.superclass) if base.superclass.respond_to?(:task_hooks)
        base.task_hooks[type].each { |i| self.instance_exec(&i) }
      end
    end

    module LoggerHelper
      def logger
        @logger || task_session[:logger]
      end
    end

    # OS/VM context where runs tasklets. Fiber or Thread.
    # It provides the session local variable in Hash.
    class TaskSession

      def self.reset!(type=:thread)
        @task_session_class = case type
                              when :thread
                                ThreadTaskSession
                              when :fiber
                                FiberTaskSession
                              end
        @task_session_class.reset_holder
      end

      def self.current
        reset! if @task_session_class.nil?
        @task_session_class.current
      end

      def self.invoke(taskclass, method, args)
        self.current.invoke(taskclass, method, args)
      end

      def initialize
        @tasklets = {}
        @hash = {}
      end

      def [](key)
        @hash[key]
      end

      def []=(key, value)
        @hash[key] = value
      end

      def invoke(taskclass, method, args)
        raise ArgumentError unless taskclass.is_a?(Class) && taskclass < Tasklet
        tasklet = Tasklet.registry[taskclass] || taskclass.new

        unless @tasklets.has_key?(tasklet)
          @tasklets[tasklet]=1
          tasklet.invoke_hook(:session_begin)
        end
        tasklet.invoke!(self, method, args)
      end

      protected
      def self.reset_holder
        raise NotImplementedError
      end
    end

    class ThreadTaskSession < TaskSession
      def self.current
        Thread.current[:task_session]
      end

      def self.reset_holder
        Thread.current[:task_session] = self.new
      end
    end

    class FiberTaskSession < TaskSession
      def self.current
        Fiber.current[:task_session]
      end

      def self.reset_holder
        Fiber.current[:task_session] = self.new
      end
    end

  end
end
