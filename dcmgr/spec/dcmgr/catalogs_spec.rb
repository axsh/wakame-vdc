# -*- coding: utf-8 -*-

require 'spec_helper'

describe Dcmgr::Catalogs::LoadBalancer do

  describe '#load' do
    let(:load_balancer_catalog) do
      Dcmgr::Catalogs.load Dcmgr::Catalogs::LoadBalancer
      Dcmgr::Catalogs.load_balancer
    end

    subject { lambda { load_balancer_catalog } }

    context 'None of the usual_paths existed' do
      it { is_expected.to raise_error RuntimeError }
    end

    context 'use minimal load_balancer.yml' do
      let(:load_balancer_catalog) do
        Dcmgr::Catalogs.load Dcmgr::Catalogs::LoadBalancer,
        ["#{Dcmgr::DCMGR_ROOT}/spec/minimal_load_balancer.yml"]
        Dcmgr::Catalogs.loadbalancer
      end

      it 'use max connection 1000' do
        expect(load_balancer_catalog.find(1000)).to eq({"hypervisor"=>"openvz", "cpu_cores"=>1, "memory_size"=>256, "quota_weight"=>1.0})
      end

      it 'use max connection 5000' do
        expect(load_balancer_catalog.find(5000)).to eq({"hypervisor"=>"openvz", "cpu_cores"=>2, "memory_size"=>512, "quota_weight"=>2.0})
      end

      it 'use unknown max connection' do
        expect(load_balancer_catalog.find(9999)).to eq(nil)
      end
    end
  end
end

describe Dcmgr::Catalogs::VirtualDataCenter do
  describe '#load' do
  end
end
