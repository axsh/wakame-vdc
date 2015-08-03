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

      ds = Dcmgr::Models::HostNode.where(id: host.id)
      allow(Isono::Models::NodeState).to receive(:filter).with(state: 'online').and_return(ds)
    end

    let(:host) { Fabricate(:host_node, hypervisor: 'kvm', node_id: 'hva.hoge') }

    it 'does whatever' do
      i = Fabricate(:instance, hypervisor: 'kvm')
      Dcmgr::Scheduler::HostNode::PipedRules.new.schedule(i)

      expect(i.host_node).to eq(host)
    end
  end
end
