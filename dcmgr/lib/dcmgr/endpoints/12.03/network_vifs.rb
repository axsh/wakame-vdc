# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/network_vifs' do

  get '/:vif_id' do
    # description "Retrieve details about a vif"
    # params id, string, required
    # params vif_id, string, required
    respond_with(R::NetworkVif.new(find_by_uuid(params[:vif_id])).generate)
  end

  namespace '/:vif_id/monitors' do
    before do
      @vif = find_by_uuid(:NetworkVif, params[:vif_id])
    end
    
    # List network monitor entries.
    get do
      respond_with(R::NetworkVifMonitorCollection.new(@vif.network_vif_monitors_dataset).generate)
    end
    
    # Show a network monitor entry.
    get '/:monitor_id' do
      monitor = find_by_uuid(M::NetworkVifMonitor, params[:monitor_id])
      respond_with(R::NetworkVifMonitor.new(monitor).generate)
    end

    # Add new network monitor entry.
    post do
      mclass = M::NetworkVifMonitor.monitor_class(params[:protocol]) || raise("Unsupported protocol: #{params[:protocol]}")
      monitor = mclass.new

      monitor.network_vif = @vif
      respond_with(R::NetworkVifMonitor.new(monitor.save).generate)
    end
    
    # Delete a network monitor entry.
    delete '/:monitor_id' do
      monitor = find_by_uuid(M::NetworkVifMonitor, params[:monitor_id])
      monitor.destroy

      respond_with([monitor.canonical_uuid])
    end
  end
end
