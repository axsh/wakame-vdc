# -*- coding: utf-8 -*-
require_relative 'helper'

require 'helper_vnet_webmock'

describe "networks" do
  M = Dcmgr::Models
  C = Dcmgr::Constants

  describe "POST" do
    use_database_cleaner_strategy_for_this_context :truncation

    let(:account) { Fabricate(:account) }

    let(:online_kvm_host_node) do
      Fabricate(:host_node, hypervisor: C::HostNode::HYPERVISOR_KVM)
    end


    before(:each)  do
      extend_dcmgr_conf_for_openvnet

      # Stub out all Isono related methods
      stub_dcmgr_syncronized_message_ready
      stub_online_host_nodes M::HostNode.where(id: online_kvm_host_node.id)
      stub_dcmgr_messaging

      allow(Dcmgr.messaging).to receive(:submit)

      vnet_network_required_params = {
        :uuid => "nw-test",
        :display_name => "nw-test",
        :ipv4_network => params[:network],
        :ipv4_prefix => params[:prefix],
        :network_mode => 'virtual'
      }
      stub_vnet_request("networks", vnet_network_required_params)

      post("networks",
           params,
           Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid)
    end

    context "with only the required parameters" do
      let(:dc_network) { Fabricate(:dc_network) }

      let(:params) do
        {
          network: "172.16.0.0",
          prefix: 24,
          dc_network: dc_network.canonical_uuid,
          network_mode: "securitygroup"
        }
      end

      it "returns json decribing the created network" do
        expect(body['dc_network']['id']).to eq params[:dc_network]
        expect(body['ipv4_network']).to eq params[:network]
        expect(body['network_mode']).to eq params[:network_mode]
      end
    end
  end
end
