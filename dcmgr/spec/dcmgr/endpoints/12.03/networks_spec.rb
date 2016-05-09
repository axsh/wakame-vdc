# -*- coding: utf-8 -*-
require_relative 'helper'

require 'helper_vnet_webmock'

describe "networks" do
  M = Dcmgr::Models
  C = Dcmgr::Constants

  before(:each) { stub_dcmgr_syncronized_message_ready }
  # Contexts can override this let to execute code before the api calls
  let(:before_api_call) {}

  let(:account) { Fabricate(:account) }
  let(:headers) do
    { Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID => account.canonical_uuid }
  end

  describe "POST" do
    use_database_cleaner_strategy_for_this_context :truncation

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

      post("networks", params, headers)
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

  describe "GET /:id" do
    before(:each) do
      before_api_call

      get("networks/#{network_id}", {}, headers)
    end

    context "with an existing network id" do
      let(:network) { Fabricate(:network, account_id: account.canonical_uuid) }
      let(:network_id) { network.canonical_uuid }

      it "shows the network" do
        expect(last_response).to be_ok

        expect(body).to eq({
          "id" => network_id,
          "uuid" => network_id,
          "account_id" => account.canonical_uuid,
          "ipv4_network" => network.ipv4_network,
          "ipv4_gw" => network.ipv4_gw,
          "prefix" => network.prefix,
          "metric" => network.metric,
          "domain_name" => network.domain_name,
          "dns_server" => network.dns_server,
          "metadata_server" => network.metadata_server,
          "metadata_server_port" => network.metadata_server_port,
          "nat_network_id" => network.nat_network_id,
          "description" => network.description.to_s,
          "created_at" => network.created_at.iso8601,
          "updated_at" => network.updated_at.iso8601,
          "network_mode" => network.network_mode,
          "bandwidth" => network.bandwidth,
          "ip_assignment" => network.ip_assignment,
          "editable" => network.editable,
          "service_type" => network.service_type,
          "display_name" => network.display_name,
          "bandwidth_mark" => network.id,
          "network_services" => network.network_service.all,
          "dc_network" => network.dc_network,
          "dhcp_server" => network.dhcp_server
        })
      end
    end

    context "with an existing network belonging to a different account" do
      let(:network_id) do
        other_acc = Fabricate(:account)
        Fabricate(:network, account_id: other_acc.canonical_uuid).canonical_uuid
      end

      it_returns_error(:UnknownUUIDResource, 404)
    end

    context "with a non existing network id" do
      let(:network_id) { "nw-nothere" }
      it_returns_error(:UnknownUUIDResource, 404)
    end

    context "with a malformed uuid" do
      let(:network_id) { "koekenbakkenvlaaien" }

      it_returns_error(:InvalidParameter, 400, "Invalid UUID Syntax: koekenbakkenvlaaien")
    end
  end

  describe "GET" do
    before(:each) do
      before_api_call
      get("networks", params, headers)
    end

    it_behaves_like 'a paging get request', :network
    it_behaves_like 'a get request with datetime range filtering', :created, :network
  end
end
