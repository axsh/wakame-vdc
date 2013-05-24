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
      stored_uuids = @vif.network_vif_monitors.map {|m| m.canonical_uuid }
      deletes = stored_uuids - input_uuids
      updates = stored_uuids - deletes

      deletes.each { |uuid|
        m = M::NetworkVifMonitor[uuid]
        next if m.nil?
        m.destroy
      }
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
        m.protocol = input['protocol'] if input['protocol']
        m.save_changes
      }
      new_items.each { |input|
        mclass = M::NetworkVifMonitor.monitor_class(input['protocol']) || raise("Unsupported protocol: #{input['protocol']}")
        monitor = mclass.new do |m|
          m.network_vif = @vif
          if input['enabled']
            m.enabled = (input['enabled'] == 'true')
          end
          m.protocol = input['protocol']
          m.title = input['title'] if !input['title'].nil? && input['title'] != ""
          m.params = input['params'] if input['params']
        end
        monitor.save
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
        :updated=>updates,
        :created=>new_items.map {|m| m['uuid']}
      }
    end

    # Add new network monitor entry.
    def single_insert
      mclass = M::NetworkVifMonitor.monitor_class(params[:protocol]) || raise("Unsupported protocol: #{params[:protocol]}")
      monitor = mclass.new do |m|
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
            elsif params[:protocol] && params[:enabled]
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
end
