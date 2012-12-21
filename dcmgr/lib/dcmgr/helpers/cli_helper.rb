# -*- coding: utf-8 -*-

require 'eventmachine'
require 'shellwords'
raise "Shellword is old version." unless Shellwords.respond_to?(:shellescape)

require 'posix/spawn'
require 'forwardable'

# force to use /bin/bash.
module POSIX
  module Spawn
    private
    def adjust_process_spawn_argv(args)
      if args.size == 1 && args[0] =~ /[ |><]/
        # single string with these characters means run it
        # through the shell
        [['/bin/bash', '/bin/bash'], '-c', args[0]]
      elsif !args[0].respond_to?(:to_ary)
        # [argv0, argv1, ...]
        [[args[0], args[0]], *args[1..-1]]
      else
        # [[cmdname, argv0], argv1, ...]
        args
      end
    end
  end
end


module Dcmgr
  module Helpers
    # class Shell
    #   include CliHelper
    #   def func
    #     tryagain do
    #       sh("/bin/ls %s", ['/home'])
    #     end
    #   end
    #
    #   def func2
    #     shell.run("/bin/ls %s", ['/home'])
    #   end
    # end
    #
    # class CgroupExample
    #   include Cgroup::CgroupContextProvider
    #   # Must be included after CgroupContextProvider.
    #   include CliHelper
    #
    #   def func
    #     cgroup_context do
    #       sh("/bin/ls %s", ['/home'])
    #       shell.run("/bin/ls %s", ['/home'])
    #     end
    #   end
    # end
    module CliHelper
      class TimeoutError < RuntimeError; end

      def tryagain(opts={:timeout=>60, :retry=>3}, &blk)
        timedout = false
        curthread = Thread.current

        timersig = EventMachine.add_timer(opts[:timeout]) {
          timedout = true
          if curthread && curthread.alive?
            curthread.raise(TimeoutError.new("timeout"))
            begin
              curthread.pass
            rescue ::Exception => e
              # any thread errors can be ignored.
            end
          end
        }

        count = opts[:retry]
        begin
          begin
            break if blk.call
          end while !timedout && ((count -= 1) >= 0)
        rescue TimeoutError => e
          raise e
        rescue RuntimeError => e
          if respond_to?(:logger)
            logger.debug("Caught Error. To be retrying....: #{e}")
          end
          retry if (count -= 1) >= 0
        ensure
          EventMachine.cancel_timer(timersig) rescue nil
        end
      end

      def sh(cmd, args=[], opts={})
        r = shell.run!(cmd, args, opts)
        {:stdout => r.out, :stderr => r.err}
      end

      # Delegate ShellRunner instance.
      #
      # puts shell.run("ls /home").out
      #
      # shell.run("ls /home").tap { |o|
      #    puts "STDOUT: " + o.out
      #    puts "STDERR: " + o.err
      # }
      #
      # # Raise exception at non-zero exit.
      # shell.run!("ls /dontexist")
      def shell
        if respond_to?(:task_session) && self.task_session && self.task_session[:shell_runner_class].is_a?(Class)
          unless self.task_session[:shell_runner_class] < ShellRunner
            raise TypeError, "Invalid ShellRunner class is set: #{self.task_session[:shell_runner_class]}"
          end
          self.task_session[:shell_runner_class].new(self)
        else
          ShellRunner.new(self)
        end
      end

      class ShellRunner

        class CommandError < StandardError
          def initialize(cmdline, cmdresult)
            msg = "Unexpected exit code=#{cmdresult.status.exitstatus}: #{cmdline}\n"
            r = cmdresult
            msg << "Command PID: #{r.status.pid}"
            msg << "\n##STDOUT=>\n#{r.out.strip}" if r.out && r.out.strip.size > 0
            msg << "\n##STDERR=>\n#{r.err.strip}" if r.err && r.err.strip.size > 0

            super(msg)
            @cmdresult = cmdresult
          end

          def out
            @cmdresult.out
          end

          def err
            @cmdresult.err
          end
        end

        def initialize(subject)
          @subject = subject
        end

        def format_tuple(cmd, args=[])
          sprintf(cmd, *args.map {|a| Shellwords.shellescape(a.to_s) })
        end

        def run(cmd, args=[], opts={})
          cmd = format_tuple(cmd, args)

          logger.info("Executing command: #{cmd}")
          # use /bin/bash instead of /bin/sh.
          r = if cmd =~ /[ |><]/
                exec(['/bin/bash', '/bin/bash'], '-c', "#{cmd}")
              else
                exec(cmd, opts)
              end

          msg = ""
          if r.success?
            msg << "Command Result: success (exit code=0)\n"
          else
            msg << "Command Result: fail (exit code=#{r.status.exitstatus})\n"
          end
          msg << "Command PID: #{r.status.pid}"
          msg << "\n##STDOUT=>\n#{r.out.strip}" if r.out && r.out.strip.size > 0
          msg << "\n##STDERR=>\n#{r.err.strip}" if r.err && r.err.strip.size > 0
          logger.debug(msg)

          r
        end

        def run!(cmd, args=[], opts={})
          run(cmd, args, opts).tap { |r|
            unless r.success?
              raise CommandError.new(r.instance_variable_get(:@argv).last, r)
            end
          }
        end

        # POSIX::Spawn.popen4 + block support
        def popen4(*args, &blk)
          pid, sin, sout, eout = posix_spawn_module.popen4(*args)
          [sin, sout, eout].each { |fd| fd.close_on_exec = true }

          return pid, sin, sout, eout unless blk

          begin
            blk.call( pid, sin, sout, eout )
            begin
              ::Process.wait(pid)
            rescue Errno::ECHILD
            end
            return $?
          ensure
            [sin, sout, eout].each { |fd| fd.close rescue nil }
          end
        end

        private

        def exec(*args)
          POSIX::Spawn::Child.new(*args)
        end

        def posix_spawn_module
          POSIX::Spawn
        end

        def logger
          (@subject.respond_to?(:logger) && @subject.logger) || Dcmgr::Task::TaskSession.current[:logger] || Dcmgr::Logger.logger
        end
      end

      class CgexecShellRunner < ShellRunner

        # Prepend "cgexec.sh -g $controller:$path -c" to the given
        # command line string.
        module CgexecArgument
          # spawn() in POSIX::Spawn is the root method used from everywhere.
          def spawn(*args)
            env, argv, options = extract_process_spawn_arguments(*args)

            # CgroupProvider#current_cgroup_context is available when
            # this module is included.
            cgctx = current_cgroup_context
            if cgctx
              if argv[0].is_a?(Array)
                h = argv.shift
                argv.unshift(h[0])
              end

              cgexec = [File.expand_path('cgexec.sh', Dcmgr.conf.script_root_path), '-g', "#{cgctx.subsystems.join(',')}:#{cgctx.scope}", '-c']
              argv = cgexec + argv
            end
            super(env, *argv, options)
          end
        end

        class Child < POSIX::Spawn::Child
          # override spawn() method comes from POSIX::Spawn module.
          include CgexecArgument
          include Cgroup::CgroupContextProvider::Delegator

          def initialize(*args)
            @cgprovider = args.shift
            super(*args)
          end
        end

        def initialize(subject)
          super
          unless subject.kind_of?(Cgroup::CgroupContextProvider)
            raise ArgumentError, "#{subject} does not provide CgroupContextProvider interface"
          end
        end

        private

        def exec(*args)
          Child.new(@subject, *args)
        end

        def posix_spawn_module
          Class.new do
            include POSIX::Spawn
            include CgexecArgument
            include Cgroup::CgroupContextProvider::Delegator

            def initialize(subject)
              raise ArgumentError unless subject.kind_of?(Cgroup::CgroupContextProvider)
              @cgprovider = subject
            end
          end.new(@subject)
        end

      end

    end
  end
end
