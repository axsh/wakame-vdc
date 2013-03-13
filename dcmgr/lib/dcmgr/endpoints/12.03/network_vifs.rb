# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network_vif'
require 'dcmgr/endpoints/12.03/responses/network_vif_monitor'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/network_vifs' do

  get '/:vif_id' do
    # description "Retrieve details about a vif"
    # params id, string, required
    # params vif_id, string, required
    respond_with(R::NetworkVif.new(find_by_uuid(:NetworkVif, params[:vif_id])).generate)
  end

  namespace '/:vif_id/monitors' do
    before do
      @vif = find_by_uuid(:NetworkVif, params[:vif_id])
    end

    # List network monitor entries.
    get do
      respond_with(R::NetworkVifMonitorCollection.new(@vif.network_vif_monitors_dataset.alives).generate)
    end

    # Bulk update interface for monitor items.
    def bulk_update
      input_uuids = []
      new_items = []
      params['monitors'].each {|idx, m|
        if m['uuid']
          input_uuids << m['uuid']
        else
          new_items << m
        end
      }
      stored_uuids = @vif.network_vif_monitors_dataset.alives.map {|m| m.canonical_uuid }
      deletes = stored_uuids - input_uuids
      updates = stored_uuids - deletes

      deletes.each { |uuid|
        m = M::NetworkVifMonitor[uuid]
        next if m.nil?
        m.destroy
      }
      modified_items = []
      updates.each { |uuid|
        input = params['monitors'].find{|idx, i| i['uuid'] == uuid }
        next if input.nil?
        input = input[1]
        
        m = M::NetworkVifMonitor[uuid]
        next if m.nil?
        if input['enabled']
          m.enabled = (input['enabled'] == 'true')
        end
        m.title = input['title'] if !input['title'].nil? && input['title'] != ""
 
        m.params = input['params'] if input['params']
        m.save_changes
        modified_items << m
      }
      created_items = []
      new_items.each { |input|
        monitor = M::NetworkVifMonitor.new do |m|
          m.network_vif = @vif
          if input['enabled']
            m.enabled = (input['enabled'] == 'true')
          end
          m.title = input['title'] if !input['title'].nil? && input['title'] != ""
          m.params = input['params'] if input['params']
        end
        monitor.save
        created_items << monitor
      }

      on_after_commit do
        deletes.each { |uuid|
          Dcmgr.messaging.event_publish("vif.monitoring.deleted",
                                        :args=>[{:vif_id=>@vif.canonical_uuid, :monitor_id=>uuid}])
        }
        updates.each {|uuid|
          Dcmgr.messaging.event_publish("vif.monitoring.updated",
                                        :args=>[{:vif_id=>@vif.canonical_uuid, :monitor_id=>uuid}])
        }
        new_items.map {|m| m['uuid'] }.each {|uuid|
          Dcmgr.messaging.event_publish("vif.monitoring.created",
                                        :args=>[{:vif_id=>@vif.canonical_uuid, :monitor_id=>uuid}])
        }
      end

      {:deleted=>deletes,
        :updated=>modified_items.map {|m| R::NetworkVifMonitor.new(m).generate },
        :created=>created_items.map {|m| R::NetworkVifMonitor.new(m).generate }
      }
    end

    # Add new network monitor entry.
    def single_insert
      monitor = M::NetworkVifMonitor.new do |m|
        m.network_vif = @vif
        if params[:enabled]
          m.enabled = (params[:enabled] == 'true')
        end

        m.title = params[:title] if params[:title] && params[:title] != ""
        m.params = params[:params] if params[:params]
      end
      monitor.save

      on_after_commit do
        Dcmgr.messaging.event_publish("vif.monitoring.created",
                                      :args=>[{:vif_id=>@vif.canonical_uuid, :monitor_id=>monitor.canonical_uuid}])
      end
      
      R::NetworkVifMonitor.new(monitor).generate
    end

    post do
      res = if params[:monitors].is_a?(Hash)
              bulk_update
            elsif params[:title] && params[:enabled]
              single_insert
            else
              # delete all items.
              params['monitors'] = {}
              bulk_update
            end

      on_after_commit do
        if @vif.instance
          Dcmgr.messaging.event_publish("instance.monitoring.refreshed",
                                        :args=>[{:instance_id=>@vif.instance.canonical_uuid}])
        end
      end

      respond_with(res)
    end

    # Show a network monitor entry.
    get '/:monitor_id' do
      monitor = M::NetworkVifMonitor[params[:monitor_id]] || raise(UnknownUUIDResource, params[:monitor_id])
      respond_with(R::NetworkVifMonitor.new(monitor).generate)
    end

    # Delete a network monitor entry.
    delete '/:monitor_id' do
      monitor = M::NetworkVifMonitor[params[:monitor_id]] || raise(UnknownUUIDResource, params[:monitor_id])
      monitor.destroy

      on_after_commit do
        Dcmgr.messaging.event_publish("vif.monitoring.deleted",
                                      :args=>[{:vif_id=>@vif.canonical_uuid, :monitor_id=>params[:monitor_id]}])
        if @vif.instance
          Dcmgr.messaging.event_publish("instance.monitoring.refreshed",
                                        :args=>[{:instance_id=>@vif.instance.canonical_uuid, :monitor_id=>params[:monitor_id]}])
        end
      end

      respond_with([monitor.canonical_uuid])
    end

    # Update a network monitor parameters.
    put '/:monitor_id' do
      monitor = M::NetworkVifMonitor[params[:monitor_id]] || raise(UnknownUUIDResource, params[:monitor_id])
      if params[:enabled]
        monitor.enabled = (params[:enabled] == 'true')
      end

      monitor.title = params[:title] if params[:title]
      monitor.params = params[:params] if params[:params]
      monitor.save_changes

      on_after_commit do
        Dcmgr.messaging.event_publish("vif.monitoring.updated",
                                      :args=>[{:vif_id=>@vif.canonical_uuid, :monitor_id=>params[:monitor_id]}])
        if @vif.instance
          Dcmgr.messaging.event_publish("instance.monitoring.refreshed",
                                        :args=>[{:instance_id=>@vif.instance.canonical_uuid, :monitor_id=>params[:monitor_id]}])
        end
      end

      respond_with(R::NetworkVifMonitor.new(monitor).generate)
    end
  end

  get '/:vif_id/external_ip' do
    vif = find_by_uuid(:NetworkVif, params[:vif_id]) || raise(UnknownUUIDResource, params[:vif_id])

    result = vif.inner_routes(:conditions => {:name => 'external-ip'}).collect { |route|
      {
        :network_uuid => route.outer_network ? route.outer_network.canonical_uuid : nil,
        :vif_uuid => route.outer_vif ? route.outer_vif.canonical_uuid : nil,
        :ipv4 => route.outer_ipv4_s
      }
    }
    
    respond_with(result)
  end

  post '/:vif_id/external_ip' do
    inner_vif = find_by_uuid(:NetworkVif, params[:vif_id]) || raise(UnknownUUIDResource, params[:vif_id])
    inner_nw = inner_vif.network || raise(NetworkVifNotAttached, params[:vif_id])
    inner_ipv4 = nil
    outer_vif = nil
    outer_ipv4 = nil

    create_options = {
      :outer => {
        :find_service => 'external-ip',
      },
      :inner => {
        :find_ipv4 => :vif_first,
      }
    }
      
    params[:network_uuid] && params[:ip_handle] && raise(InvalidParameter, "network_uuid && ip_handle")

    if params[:network_uuid]
      outer_nw = find_by_uuid(:Network, params[:network_uuid]) || raise(UnknownUUIDResource, params[:network_uuid])
      create_options[:lease_ipv4] = :default
    elsif params[:ip_handle]
      outer_ip_handle = M::IpHandle[params[:ip_handle]] || raise(UnknownUUIDResource, params[:ip_handle])
      outer_nw = outer_ip_handle.ip_lease.network

      if @account && outer_ip_handle.ip_pool.account_id != @account.canonical_uuid
        raise(E::UnknownUUIDResource, params[:ip_handle])
      end

      create_options[:outer][:ip_handle] = outer_ip_handle
    else
      raise(InvalidParameter, "")
    end

    route_data = {
      :route_type => 'external-ip',
      :outer_network_id => outer_nw.id,
      :inner_network_id => inner_nw.id,

      :create_options => create_options
    }

    route_data[:outer_vif_id] = outer_vif.id if outer_vif
    route_data[:inner_vif_id] = inner_vif.id if inner_vif
    route_data[:outer_ipv4] = outer_ipv4 if outer_ipv4
    route_data[:inner_ipv4] = inner_ipv4 if inner_ipv4

    # Validate ip pool has dc network?

    begin
      route = M::NetworkRoute.create(route_data)
    rescue Sequel::ValidationFailed => e
      raise(E::InvalidParameter, e.message)
    end

    respond_with({ :network_uuid => route.outer_network.canonical_uuid,
                   :vif_uuid => route.outer_vif.canonical_uuid,
                   :ipv4 => route.outer_ipv4_s,
                 })
  end

  delete '/:vif_id/external_ip' do
    inner_vif = find_by_uuid(:NetworkVif, params[:vif_id]) || raise(UnknownUUIDResource, params[:vif_id])
    inner_nw = inner_vif.network || raise(NetworkVifNotAttached, params[:vif_id])
    inner_ipv4 = params[:inner_ipv4]
    outer_ipv4 = params[:outer_ipv4]

    if params[:ip_handle]
      outer_ipv4.nil? || raise(E::InvalidParameter, "Cannot mix 'ip_handle' and 'outer_ipv4' parameters.")

      outer_ip_handle = M::IpHandle[params[:ip_handle]] || raise(UnknownUUIDResource, params[:ip_handle])

      outer_nw = outer_ip_handle.ip_lease.network
      outer_vif = outer_ip_handle.ip_lease.network_vif
      outer_ipv4 = outer_ip_handle.ip_lease.ipv4_s

      if @account && outer_ip_handle.ip_pool.account_id != @account.canonical_uuid
        raise(E::UnknownUUIDResource, params[:ip_handle])
      end

    elsif params[:network_uuid]
      outer_nw = find_by_uuid(:Network, params[:network_uuid]) ||
        raise(UnknownUUIDResource, params[:network_uuid])
      outer_vif = outer_nw.network_vifs_with_service(:network_services__name => 'external-ip').first ||
        raise(UnknownNetworkService, 'external-ip')
    else
      raise(E::InvalidParameter, "")
    end

    ds = M::NetworkRoute.dataset.routes_between_vifs(outer_vif, inner_vif)
    ds = ds.where(:network_routes__inner_ipv4 => IPAddress::IPv4.new(inner_ipv4).to_i) if inner_ipv4
    ds = ds.where(:network_routes__outer_ipv4 => IPAddress::IPv4.new(outer_ipv4).to_i) if outer_ipv4

    result = []

    ds.each { |route|
      result << {
        :network_uuid => route.outer_network.canonical_uuid,
        :vif_uuid => route.outer_vif.canonical_uuid,
        :ipv4 => route.outer_ipv4_s,
      }

      route.destroy
    }
    
    respond_with(result)
  end

end
