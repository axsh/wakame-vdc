# -*- coding: utf-8 -*-

module Dcmgr
  module Monitor
    class ResourceCapture
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      SUPPORT_METRIC_NAMES = {
        "cpu" => ['time', 'pid', 'cpu.usr_usage', 'cpu.system_usage', 'cpu.guest_usage', 'cpu.usage', 'cpu.number', 'cpu.cswch', 'cpu.nvcswch', 'cpu.usr_ms', 'cpu.system_ms', 'cpu.guest_ms'],
        "memory" => ['time', 'pid', 'memory.minflt', 'memory.majflt', 'memory.vsz', 'memory.rss', 'memory.usage', 'memory.minflt-nr', 'memory.majflt-nr']
      }.freeze

      def initialize(node)
        @node = node
        @rpc = Isono::NodeModules::RpcChannel.new(@node)
      end

      def get_resources(metric_name)
        # TODO: add volume and network vif
        list = @rpc.request('hva-collector', 'get_resource_monitor_data', @node.node_id)

        h = {}
        list.each {|i|
          begin
            pidfile = "#{Dcmgr::Configurations.hva.vm_data_dir}/#{i[:uuid]}/kvm.pid"
            raise "Unable to find the pid file: #{i[:uuid]}" unless File.exists?(pidfile)
            logger.debug("Find pidfile: #{pidfile}")

            kvmpid = File.read(pidfile)
            logger.debug("#{i[:uuid]} pid: #{kvmpid}")
            tryagain(opts={:timeout=>Dcmgr::Configurations.hva.capture.timeout_sec, :retry=>Dcmgr::Configurations.hva.capture.retry_count}) do
              h["#{i[:uuid]}"] = parse_pidstat(metric_name, exec_pidstat(metric_name, kvmpid.to_i))
            end
            h["#{i[:uuid]}"]["time"] = Time.at(h["#{i[:uuid]}"]["time"].to_i)
          rescue TimeoutError => e
            logger.debug("Caught Error. #{e} pidstat #{i[:uuid]}")
            h["#{i[:uuid]}"] = create_error_data(metric_name)
          rescue Exception => e
            logger.error("Error occured. [Instance ID: #{i[:uuid]}]: #{e}")
            h["#{i[:uuid]}"] = create_error_data(metric_name)
          ensure
            unless i[:vif].blank?
              vif = i[:vif].first
              h["#{i[:uuid]}"] = h["#{i[:uuid]}"].merge({"ipaddr"=>vif[:ipv4][:address]}) unless vif[:ipv4].blank?
            end
          end
        }
        h
      end

      private
      def exec_pidstat(metric_name, pid)
        raise ArgumentError unless metric_name.is_a?(String)
        raise ArgumentError unless pid.is_a?(Integer)

        option = case metric_name
                 when "cpu"
                   " -u -w"
                 when "memory"
                   " -r"
                 else
                   raise "Unknown Metric type: #{metric_name}"
                 end
        sh("pidstat -h #{option} -T ALL -p #{pid} 1 1")
      end

      def parse_pidstat(metric_name, data)
        raise ArgumentError unless metric_name.is_a?(String)
        raise ArgumentError unless data.is_a?(Hash)

        metric = data[:stdout].split(/\n/)
        metric.shift

        initial_keys = SUPPORT_METRIC_NAMES[metric_name]
        raise "Unknown Metric type: #{metric_name}" if initial_keys.nil?
        values = []
        metric_value = metric.map {|m|  m.lstrip!}.compact
        metric_value.each {|m|
          m = m.split(nil)
          m.pop
          m.slice!(0,2) if m.size <= 5
          values << m
        }
        Hash[*initial_keys.zip(values.flatten).flatten]
      end

      def create_error_data(metric_name)
        raise ArgumentError unless metric_name.is_a?(String)

        hash = {}
        SUPPORT_METRIC_NAMES[metric_name].each {|m| hash[m] = nil}
        hash.merge({"time" => Time.now})
      end
    end
  end
end
