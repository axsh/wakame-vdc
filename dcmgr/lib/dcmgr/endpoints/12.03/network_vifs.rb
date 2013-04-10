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

  put '/:vif_id/add_security_group' do
    vnic = find_by_uuid(:NetworkVif, params[:vif_id])
    group = find_by_uuid(:SecurityGroup, params[:security_group_id])
    # I am using UnknownUUIDResource and not UnknownSecurityGroup because I want to throw the same error that's thrown
    # by find_by_uuid if the group wasn't found in the database.
    raise E::UnknownUUIDResource, params[:security_group_id].to_s unless group && group.account_id == vnic.account_id

    if vnic.security_groups.member?(group)
      raise E::DuplicatedSecurityGroup, "'#{params[:security_group_id]}' is already assigned to '#{params[:vif_id]}'"
    end

    vnic.add_security_group(group)
    on_after_commit do
      Dcmgr.messaging.event_publish("#{group.canonical_uuid}/vnic_joined",:args=>[vnic.canonical_uuid])
      Dcmgr.messaging.event_publish("#{vnic.canonical_uuid}/joined_group",:args=>[group.canonical_uuid])
    end

    respond_with(R::NetworkVif.new(find_by_uuid(:NetworkVif, params[:vif_id])).generate)
  end

  put '/:vif_id/remove_security_group' do
    vnic = find_by_uuid(:NetworkVif, params[:vif_id])
    group = vnic.security_groups_dataset.filter(:uuid => M::SecurityGroup.trim_uuid(params[:security_group_id]) ).first

    raise E::UnknownSecurityGroup, "'#{params[:security_group_id]}' is not assigned to '#{params[:vif_id]}'" unless group

    vnic.remove_security_group(group)
    on_after_commit do
      Dcmgr.messaging.event_publish("#{group.canonical_uuid}/vnic_left",:args=>[vnic.canonical_uuid])
      Dcmgr.messaging.event_publish("#{vnic.canonical_uuid}/left_group",:args=>[group.canonical_uuid])
    end

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

    ds = M::NetworkRoute.dataset
    ds = ds.join_with_inner_ip_leases.where(:inner_ip_leases__network_vif_id => vif.id)
    ds = ds.select_all(:network_routes).alives

    result = ds.collect { |route|
      {
        :network_id => route.outer_network ? route.outer_network.canonical_uuid : nil,
        :vif_id => route.outer_vif ? route.outer_vif.canonical_uuid : nil,
        :ip_handle_id => route.outer_lease.ip_handle ? route.outer_lease.ip_handle.canonical_uuid : nil,
        :ipv4 => route.outer_lease.ipv4_s,
      }
    }
    
    respond_with(result)
  end

  post '/:vif_id/external_ip' do
    inner_vif = find_by_uuid(:NetworkVif, params[:vif_id]) || raise(UnknownUUIDResource, params[:vif_id])
    inner_nw = inner_vif.network || raise(NetworkVifNotAttached, params[:vif_id])

    params[:ip_handle_id] || raise(InvalidParameter, "Missing ip_handle_id")

    if params[:ip_handle_filter]
      ip_handle_dataset = M::IpHandle.dataset.where(:uuid => M::IpHandle.trim_uuid(params[:ip_handle_id]))
      outer_ip_handle = dataset_filter(ip_handle_dataset, params[:ip_handle_filter]).first
    else
      outer_ip_handle = M::IpHandle[params[:ip_handle_id]]
    end

    outer_ip_handle || raise(UnknownUUIDResource, params[:ip_handle_id])

    if @account && outer_ip_handle.ip_pool.account_id != @account.canonical_uuid
      raise(E::UnknownUUIDResource, params[:ip_handle_id])
    end

    create_options = {
      :outer => {
        :find_service => 'external-ip',
        :network => outer_ip_handle.ip_lease.network,
        :network_vif => outer_ip_handle.ip_lease.network_vif,
      },
      :inner => {
        :find_ipv4 => :vif_first,
        :network => inner_nw,
        :network_vif => inner_vif,
      }
    }
      
    route_data = {
      :route_type => 'external-ip',
      :outer_lease_id => outer_ip_handle.ip_lease.id,

      :create_options => create_options
    }

    begin
      route = M::NetworkRoute.create(route_data)
    rescue Sequel::ValidationFailed => e
      raise(E::InvalidParameter, e.message)
    end

    respond_with({ :network_id => route.outer_network.canonical_uuid,
                   :vif_id => route.outer_vif.canonical_uuid,
                   :ip_handle_id => outer_ip_handle.canonical_uuid,
                   :ipv4 => route.outer_lease.ipv4_s,
                 })
  end

  delete '/:vif_id/external_ip' do
    inner_vif = find_by_uuid(:NetworkVif, params[:vif_id]) || raise(UnknownUUIDResource, params[:vif_id])
    inner_nw = inner_vif.network || raise(NetworkVifNotAttached, params[:vif_id])

    params[:ip_handle_id] || raise(InvalidParameter, "Missing ip_handle")

    outer_ip_handle = M::IpHandle[params[:ip_handle_id]] || raise(UnknownUUIDResource, params[:ip_handle_id])

    if @account && outer_ip_handle.ip_pool.account_id != @account.canonical_uuid
      raise(E::UnknownUUIDResource, params[:ip_handle_id])
    end

    ds = M::NetworkRoute.dataset
    ds = ds.where(:network_routes__outer_lease_id => outer_ip_handle.ip_lease.id)
    ds = ds.join_with_inner_ip_leases.where(:inner_ip_leases__network_vif_id => inner_vif.id)
    ds = ds.alives.select_all(:network_routes)

    result = []

    ds.each { |route|
      result << {
        :network_id => route.outer_network.canonical_uuid,
        :vif_id => route.outer_vif.canonical_uuid,
        :ip_handle_id => route.outer_lease.ip_handle ? route.outer_lease.ip_handle.canonical_uuid : nil,
        :ipv4 => route.outer_lease.ipv4_s,
      }

      route.destroy
    }

    respond_with(result)
  end

end
