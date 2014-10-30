# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module OpenFlow

      class OvsOfctl
        include Dcmgr::Logger
        attr_accessor :ovs_ofctl
        attr_accessor :ovs_vsctl
        attr_accessor :verbose
        attr_accessor :switch_name

        def initialize
          # TODO: Make ovs_vsctl use a real config option.
          @ovs_ofctl = Dcmgr::Configurations.hva.ovs_ofctl_path
          @ovs_vsctl = Dcmgr::Configurations.hva.ovs_ofctl_path.dup
          @ovs_vsctl[/ovs-ofctl/] = 'ovs-vsctl'

          @verbose = Dcmgr::Configurations.hva.verbose_openflow
        end

        def get_bridge_name datapath_id
          command = "#{@ovs_vsctl} --no-heading -- --columns=name find bridge datapath_id=%016x" % datapath_id
          logger.debug command if verbose == true
          /^"(.*)"/.match(`#{command}`)[1]
        end

        def add_flow flow
          command = "#{@ovs_ofctl} add-flow #{switch_name} #{flow.match_to_s},actions=#{flow.actions_to_s}"
          logger.debug "'#{command}' => #{system(command)}."
        end

        def add_flows_from_list flows
          recmds = []

          eos = "__EOS_#{Isono::Util.gen_id}___"
          recmds << "#{@ovs_ofctl} add-flow #{switch_name} - <<'#{eos}'"
          flows.each { |flow|
            full_flow = "#{flow.match_to_s},actions=#{flow.actions_to_s}"
            logger.debug "ovs-ofctl add-flow #{switch_name} #{full_flow}" if verbose == true
            recmds << full_flow
          }
          recmds << "#{eos}"

          logger.debug("applying flow(s): #{recmds.size - 2}")
          system(recmds.join("\n"))
        end

        def del_flows_from_list flows
          recmds = []

          eos = "__EOS_#{Isono::Util.gen_id}___"
          recmds << "#{@ovs_ofctl} del-flows #{switch_name} - <<'#{eos}'"
          flows.each { |flow|
            full_flow = "#{flow.match_sparse_to_s}"
            logger.debug "ovs-ofctl del-flow #{switch_name} #{full_flow}" if verbose == true
            recmds << full_flow
          }
          recmds << "#{eos}"

          logger.debug("removing flow(s): #{recmds.size - 2}")
          system(recmds.join("\n"))
        end

        def add_gre_tunnel tunnel_name, remote_ip, key
          system("#{@ovs_vsctl} add-port #{switch_name} #{tunnel_name} -- set interface #{tunnel_name} type=gre options:remote_ip=#{remote_ip} options:key=#{key}")
        end

      end

    end
  end
end
