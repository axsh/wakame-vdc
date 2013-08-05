# -*- coding: utf-8 -*-

module Dcmgr
  module Monitor
    class ResourceCapture
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      SUPPORT_METRIC_NAMES = {
        "cpu" => ['time', 'pid', 'usr_usage', 'system_usage', 'guest_usage', 'usage', 'cpu_number', 'cswch', 'nvcswch', 'usr_ms', 'system_ms', 'guest_ms'],
        "memory" => ['time', 'pid', 'minflt', 'majflt', 'vsz', 'rss', 'usage', 'minflt-nr', 'majflt-nr']
      }.freeze

      def initialize(node)
        @node = node
        @rpc = Isono::NodeModules::RpcChannel.new(@node)
      end

      def get_resources
        # TODO: add volume and network vif
        instlst = @rpc.request('hva-collector', 'get_instance_monitor_data', @node.node_id)

        h = {}
        instlst.each {|i|
          begin
            h["#{i[:uuid]}"] = {}

            pidfile = "#{Dcmgr.conf.vm_data_dir}/#{i[:uuid]}/kvm.pid"
            raise "Unable to find the pid file: #{i[:uuid]}" unless File.exists?(pidfile)
            logger.debug("Find pidfile: #{pidfile}")

            kvmpid = File.read(pidfile)
            logger.debug("#{i[:uuid]} pid: #{kvmpid}")

            cpu = sh("pidstat -h -u -w -T ALL -p #{kvmpid}")
            h["#{i[:uuid]}"]["cpu"] = parse_pidstat("cpu", cpu)

            memory = sh("pidstat -h -r -T ALL -p #{kvmpid}")
            h["#{i[:uuid]}"]["memory"] = parse_pidstat("memory", memory)

            logger.debug(h)

          rescue Exception => e
            logger.error("Error occured. [Instance ID: #{i[:uuid]}]")
            logger.error(e)
          end
        }
        h
      end

      private
      def parse_pidstat(metric_name, data)
        raise ArgumentError unless metric_name.is_a?(String)
        raise ArgumentError unless data.is_a?(Hash)

        metric = data[:stdout].split(/\n/)
        metric.shift

        initial_keys = SUPPORT_METRIC_NAMES[metric_name]
        raise "Unknown Metric type: #{metric_name}" if initial_keys.nil?

        values = []
        metric.each {|m|
          next if m.empty?
          m.lstrip!
          m = m.split(nil)
          m.pop
          next if m.include?("#")
          values << m
        }
        Hash[*initial_keys.zip(values.flatten.uniq).flatten]
      end

    end
  end
end
