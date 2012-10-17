# -*- coding: utf-8 -*-

module Dcmgr
  module Rack
    # Rack middleware for running initialization/setup procedure.
    # Case 1: only when the HTTP request came first time.
    # Case 2: every time when the HTTP request comes.
    #
    # ex.
    # use InitializeFirstRequest, proc {
    #   # run setup codes. for example, establish database connection etc..
    # }
    #
    class RunInitializer
      def initialize(app, run_once, run_every=nil)
        raise ArgumentError unless run_once.nil? || run_once.is_a?(Proc)
        raise ArgumentError unless run_every.nil? || run_every.is_a?(Proc)
        @app = app
        @run_once_block = run_once
        @run_every_block = run_every
      end

      def call(env)
        def call(env)
          if @run_every_block
            @run_every_block.arity == 1 ? @run_every_block.call(env) : @run_every_block.call
          end
          @app.call(env)
        end

        if @run_once_block
          @run_once_block.arity == 1 ? @run_once_block.call(env) : @run_once_block.call
        end
        if @run_every_block
          @run_every_block.arity == 1 ? @run_every_block.call(env) : @run_every_block.call
        end
        @app.call(env)
      end

    end
  end
end
