# -*- coding: utf-8 -*-

require 'spec_helper'
require_relative '../../endpoints/12.03/helper'

describe Dcmgr::Scheduler::HostNode::PipedRules do
  describe '#schedule' do
    before do
      Dcmgr::Configurations.dcmgr.parse_dsl do |me|
        me.instance_eval('
          service_type("std", "StdServiceType") {
            host_node_scheduler(:PipedRules) do

              through(:RequestParamToGroup) {
                default "hng-shhost"

                key "host_node_group"
                pair "local", "hng-local"
              }
              through(:LeastUsageBy) {
                key "memory_size"
              }

            end
          }
        ')
      end

      host_ids = host_groups.map do |hng|
        hng.mapped_uuids.map do |h|
          h.id
        end
      end

      host_ids.each do |h|
        ds = Dcmgr::Models::HostNode.where(id: h)
        allow(Isono::Models::NodeState).to receive(:filter).with(state: 'online').and_return(ds)
      end

      svc_type = Dcmgr::Scheduler.service_type(instance)
      svc_type.host_node.schedule(instance)
    end
    let(:instance) { Fabricate(:instance, hypervisor: 'kvm', request_params: {"host_node_group" => "local"}) }

    context 'with a single host' do
      let(:hosts) do
        h = Fabricate(:host_node, uuid: 'kvm1', hypervisor: 'kvm', node_id: 'hva.kvm1')
        [h]
      end

      let(:host_groups) do
        hng = Fabricate(:host_node_group, uuid: 'hng-local', name: 'hng-local')
        hng.map_resource(hosts.first, 0)
        [hng]
      end

      it 'uses the host' do
        expect(instance.host_node).to eq(hosts.first)
      end
    end
  end
end
