# -*- coding: utf-8 -*-

require 'eventmachine'
require 'shellwords'
raise "Shellword is old version." unless Shellwords.respond_to?(:shellescape)

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
        
        outbuf = `#{cmd}`
        stat = $?
        logger.debug("Exec command (pid=#{stat.pid}): #{cmd}")
        msg = "Command output:"
        msg << "\nSTDOUT:\n#{outbuf.strip}" if outbuf && outbuf.strip.size > 0
        if stat.exitstatus != opts[:expect_exitcode]
          raise CommandError.new("Unexpected exit code=#{stat.exitstatus} (expected=#{opts[:expect_exitcode]})", \
                                 outbuf, '')
        end
        {:stdout => outbuf, :stderr => ''}
      end
    end
  end
end
