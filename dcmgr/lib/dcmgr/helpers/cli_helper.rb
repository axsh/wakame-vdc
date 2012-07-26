# -*- coding: utf-8 -*-

require 'eventmachine'
require 'shellwords'
raise "Shellword is old version." unless Shellwords.respond_to?(:shellescape)

require 'posix/spawn'
require 'forwardable'

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
        logger.debug("Executing command: #{cmd}, #{args}")
        r = shell.run!(cmd, args, opts)

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
        ShellRunner
      end

      module ShellRunner
        extend self

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

        def run(cmd, args=[], opts={})
          cmd = sprintf(cmd, *args.map {|a| Shellwords.shellescape(a.to_s) })

          exec(cmd, opts)
        end
        
        def run!(cmd, args=[], opts={})
          run(cmd, args, opts).tap { |r|
            unless r.success?
              raise CommandError.new(r.instance_variable_get(:@argv), r)
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
          ensure
            [sin, sout, eout].each { |fd| fd.close rescue nil }
          end
        end

        private

        def exec(cmd, opts)
          POSIX::Spawn::Child.new(cmd, opts)
        end

        def posix_spawn_module
          POSIX::Spawn
        end
      end

      # This module does not provide class methods.
      # Need to include to the class having Cgroup::CgroupContextProvider.
      module CgexecShellRunner
        include ShellRunner

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
              if argv[0] == ["/bin/sh", "/bin/sh"] && argv[1] == "-c"
                argv.shift
                argv.shift
              end
              
              cgexec = [[File.expand_path('cgexec.sh', Dcmgr.conf.script_root_path), File.expand_path('cgexec.sh', Dcmgr.conf.script_root_path)], '-g', "#{cgctx.subsystems.join(',')}:#{cgctx.scope}", '-c']
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

        class Delegator
          include CgexecShellRunner
          include Cgroup::CgroupContextProvider::Delegator
          
          def initialize(subject)
            raise ArgumentError unless subject.class < Cgroup::CgroupContextProvider
            @cgprovider = subject
          end
        end

        private
        
        def exec(cmd, opts={})
          Child.new(self, cmd, opts)
        end

        def posix_spawn_module
          Class.new do
            include POSIX::Spawn
            include CgexecArgument
            include Cgroup::CgroupContextProvider::Delegator

            def initialize(subject)
              raise ArgumentError unless subject.class < Cgroup::CgroupContextProvider
              @cgprovider = subject
            end
          end.new(self)
        end

      end

      def self.included(klass)
        if klass < Cgroup::CgroupContextProvider
          klass.class_eval {
            def shell
              CgexecShellRunner::Delegator.new(self)
            end
          }
        end
      end
      
    end
  end
end
