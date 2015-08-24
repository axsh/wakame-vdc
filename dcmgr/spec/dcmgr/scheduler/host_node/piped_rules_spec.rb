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
                pair "local1", "hng-local1"
                pair "local2", "hng-local2"
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

      ds = Dcmgr::Models::HostNode.where(id: host_ids.flatten!)
      allow(Isono::Models::NodeState).to receive(:filter).with(state: 'online').and_return(ds)

      instances.each do |i|
        svc_type = Dcmgr::Scheduler.service_type(i)
        svc_type.host_node.schedule(i)
        i.save_changes
      end
    end

    let(:instances) do
      i = Fabricate(:instance, hypervisor: 'kvm', request_params: {"host_node_group" => "local1"})
      [i]
    end

    let(:hosts) do
      h = Fabricate(:host_node, uuid: 'kvm1', hypervisor: 'kvm', node_id: 'hva.kvm1')
      [h]
    end

    let(:host_groups) do
      hng = Fabricate(:host_node_group, uuid: 'hng-local1', name: 'hng-local1')
      hosts.each { |h| hng.map_resource(h, 0) }
      [hng]
    end

    context 'with a single group' do
      context 'with a single host' do
        it 'uses the host' do
          expect(instances.first.host_node).to eq(hosts.first)
        end
      end

      context 'with two hosts and two instances' do
        let(:instances) do
          2.times.map do
            Fabricate(:instance, hypervisor: 'kvm', request_params: {"host_node_group" => "local1"})
          end
        end

        let(:hosts) do
          2.times.map.with_index(1) do |n, i|
            Fabricate(:host_node, uuid: "kvm#{i}", hypervisor: 'kvm', node_id: "hva.kvm#{i}")
          end
        end

        it 'assigns one instance per host node' do
          expect(instances.first.host_node).to eq(hosts.first)
          expect(instances.last.host_node).to eq(hosts.last)
        end
      end
    end

    context 'with two group' do
      context 'with two hosts and two instances' do
        let(:instances) do
          2.times.map.with_index(1) do |n, i|
            Fabricate(:instance, hypervisor: 'kvm', request_params: {"host_node_group" => "local#{i}"})
          end
        end

        let(:hosts) do
          2.times.map.with_index(1) do |n, i|
            Fabricate(:host_node, uuid: "kvm#{i}", hypervisor: 'kvm', node_id: "hva.kvm#{i}")
          end
        end

        let(:host_groups) do
          hngs = 2.times.map.with_index(1) do |n, i|
            hng = Fabricate(:host_node_group, uuid: "hng-local#{i}", name: "hng-local#{i}")
          end
          hngs.zip(hosts) do |hng, h|
            hng.map_resource(h, 0)
          end
          hngs
        end

        it 'assigns one host node per host node group' do
          expect(hosts.first).to eq(host_groups.first.mapped_resources.first)
          expect(hosts.last).to eq(host_groups.last.mapped_resources.first)
        end

        it 'assigns one instance per host node' do
          expect(instances.first.host_node).to eq(hosts.first)
          expect(instances.last.host_node).to eq(hosts.last)
        end
      end
    end
  end
end
