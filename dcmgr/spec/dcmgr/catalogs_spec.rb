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
    let(:virtual_data_center_catalog) do
      Dcmgr::Catalogs.load Dcmgr::Catalogs::VirtualDataCenter
      Dcmgr::Catalogs.virtualdatacenter
    end

    subject { lambda { virtual_data_center_catalog } }

    context 'None of the usual_paths existed' do
      it { is_expected.to raise_error RuntimeError }
    end

    context 'use minimal_virtual_data_center.yml' do
      let(:virtual_data_center_catalog) do
        Dcmgr::Catalogs.load Dcmgr::Catalogs::VirtualDataCenter,
        ["#{Dcmgr::DCMGR_ROOT}/spec/minimal_virtual_data_center.yml"]
        Dcmgr::Catalogs.virtualdatacenter
      end

      it 'use instance_spec small' do
        expect(virtual_data_center_catalog.instance_spec["small"]).to eq({"cpu_cores"=>1})
      end

      it 'use vdc_spec docker' do
        expect(virtual_data_center_catalog.vdc_spec["docker"]).to eq({"instance_spec"=>"small"})
      end

      it 'use unknown instance_spec' do
        expect(virtual_data_center_catalog.instance_spec["medium"]).to eq(nil)
      end

      it 'use unknown vdc_spec' do
        expect(virtual_data_center_catalog.vdc_spec["openstack"]).to eq(nil)
      end
    end
  end
end
