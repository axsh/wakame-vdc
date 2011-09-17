# -*- coding: utf-8 -*-

require 'eventmachine'
require 'shellwords'
raise "Shellword is old version." unless Shellwords.respond_to?(:shellescape)
require 'open4'

module Dcmgr
  module Helpers
    module CliHelper
      class TimeoutError < RuntimeError; end
      
      def tryagain(opts={:timeout=>60, :retry=>3}, &blk)
        timedout = false
        curthread = Thread.current

        timersig = EventMachine.add_timer(opts[:timeout]) {
          timedout = true
          if curthread && curthread.alive?
            curthread.raise(TimeoutError.new("timeout"))
            # call .pass only when the target thread is not died yet.
            curthread.pass  unless curthread.stop?
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

      class CommandError < StandardError
        attr_reader :stderr, :stdout
        def initialize(msg, stdout, stderr)
          super(msg)
          @stdout = stdout
          @stderr = stderr
        end
      end
      
      def sh(cmd, args=[], opts={})
        opts = opts.merge({:expect_exitcode=>0})
        cmd = sprintf(cmd, *args.map {|a| Shellwords.shellescape(a.to_s) })

        outbuf = errbuf = ''
        blk = proc {|pid, stdin, stdout, stderr|
          stdin.close
          outbuf = stdout.read
          errbuf = stderr.read
        }
        stat = Open4::popen4(cmd, &blk)
        if self.respond_to?(:logger)
          logger.debug("Exec command (pid=#{stat.pid}): #{cmd}")
          msg = "Command output:"
          msg << "\nSTDOUT:\n#{outbuf.strip}" if outbuf && outbuf.strip.size > 0
          msg << "\nSTDERR:\n#{errbuf.strip}" if errbuf && errbuf.strip.size > 0
          logger.debug(msg)
        end
        if stat.exitstatus != opts[:expect_exitcode]
          raise CommandError.new("Unexpected exit code=#{stat.exitstatus} (expected=#{opts[:expect_exitcode]})", \
            outbuf, errbuf)
        end
        {:stdout => outbuf, :stderr => errbuf}
      end
    end

  end
end
