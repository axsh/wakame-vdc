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
    # # Create new TaskA object always.
    # TaskInvoker.invoke(TaskA, :func1, ['1', '2'])
    # # => 11
    # # => 1
    # # => 2
    #
    # # Create TaskA object once in earlier stage then call method of
    # # the object. So Tasklet#initialize can be used for loading conf files etc.
    # TaskInvoker.register(TaskA.new(20))
    # 
    # TaskInvoker.invoke(TaskA, :func2)
    # # => 21
    # TaskInvoker.invoke(TaskA, :func2)
    # # => 21
    #
    # # Task session example.
    # invoker = TaskInvoker.new
    # invoker.invoke(TaskA, :func3)
    # # => 1
    # invoker.invoke(TaskA, :func3)
    # # => 2
    class Tasklet
      class << self
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

        private
        
        def inherited(klass)
          klass.reset!
        end
      end

      self.reset!
      
      def invoke(session, method, args)
        raise ArgumentError unless session.is_a?(TaskSession)
        dup.invoke!(session, method, args)
      end

      def invoke_hook(type, args=[])
        invoke_hook!(type)
      end

      module Helpers
        def task_session
          @task_session
        end
        alias :session :task_session
      end

      include Helpers

      private
      
      def invoke!(session, method, args=[])
        raise "Unknown method: #{self.class}\##{method}" unless self.respond_to?(method)

        @task_session = session
        @method = method
        @args = args
        
        begin
          invoke_hook! :before
          # method must be public.
          self.send(method, *args)
        ensure
          invoke_hook! :after
        end
      end

      def invoke_hook!(type, base=self.class)
        invoke_hook!(type, base.superclass) if base.superclass.respond_to?(:task_hooks)
        base.task_hooks[type].each { |i| self.instance_exec(&i) }
      end
    end

    class TaskInvoker
      @registry = {}
      
      def self.invoke(taskclass, method, args)
        self.new.invoke(taskclass, method, args)
      end

      def self.register(tasklet)
        @registry[tasklet.class] = tasklet
      end

      def self.registry
        @registry
      end

      attr_reader :task_session
      
      def initialize(session = ThreadTaskSession.new)
        @task_session = session
      end

      def invoke(taskclass, method, args)
        raise ArgumentError unless taskclass.is_a?(Class) && taskclass < Tasklet
        tasklet = self.class.registry[taskclass]
        tasklet = tasklet.nil? ? taskclass.new : tasklet.dup

        @task_session.invoke(tasklet, method, args)
      end
    end

    # OS/VM context where runs tasklets. Fiber or Thread.
    # It provides the session local variable in Hash.
    class TaskSession
      def initialize
        @tasklets = {}
        reset_holder
      end
      
      def [](key)
        hash_holder[key]
      end

      def []=(key, value)
        hash_holder[key] = value
      end

      def invoke(tasklet, method, args)
        raise ArgumentError unless tasklet.is_a?(Tasklet)
        unless @tasklets.has_key?(tasklet)
          @tasklets[tasklet]=1
          tasklet.invoke_hook(:session_begin)
        end
        tasklet.invoke(self, method, args)
      end

      protected
      def hash_holder
        raise NotImplementedError
      end

      def reset_holder
        raise NotImplementedError
      end
    end

    class ThreadTaskSession < TaskSession
      def hash_holder
        Thread.current[:task_session]
      end

      def reset_holder
        Thread.current[:task_session] = {}
      end
    end

    class FiberTaskSession < TaskSession
      def hash_holder
        Fiber.current[:task_session]
      end

      def reset_holder
        Fiber.current[:task_session] = {}
      end
    end

  end
end
