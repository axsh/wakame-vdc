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

              through(:LeastUsageBy) {
                key "memory_size"
              }

            end
          }
        ')
      end

      host_ids = hosts.map { |h| h.id }
      ds = Dcmgr::Models::HostNode.where(id: host_ids)
      allow(Isono::Models::NodeState).to receive(:filter).with(state: 'online').and_return(ds)

      Dcmgr::Scheduler::HostNode::PipedRules.new.schedule(instance)
    end
    let(:instance) { Fabricate(:instance, hypervisor: 'kvm') }

    context 'with a single host' do
      let(:hosts) do
        h = Fabricate(:host_node, hypervisor: 'kvm', node_id: 'hva.hoge')
        [h]
      end

      it 'uses the host' do
        expect(instance.host_node).to eq(hosts.first)
      end
    end
  end
end
