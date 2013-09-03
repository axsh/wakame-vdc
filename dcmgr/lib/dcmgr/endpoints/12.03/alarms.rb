# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/alarm'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/alarms' do

  CA = Dcmgr::Constants::Alarm
  CI = Dcmgr::Constants::Instance

  get do

    ds = M::Alarm.dataset

    if params[:resource_id]
      ds = ds.filter(:resource_id=>params[:resource_id])
    end

    if params[:metric_name]
      type, key = params[:metric_name].split('.')
      if key == '*'
        ds = ds.filter(:metric_name.like("#{type}%"))
      else
        ds = ds.filter(:metric_name=>params[:metric_name])
      end
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    collection_respond_with(ds) do |paging_ds|
      R::AlarmCollection.new(paging_ds).generate
    end
  end

  post do
    if params['resource_id'].blank?
      raise E::UnknownResourceID, "#{params['resource_id']}"
    end

    # TODO: add volume and network vif
    instance = find_by_uuid(:Instance, params['resource_id'])
    raise E::InvalidInstanceState, instance.state if [CI::STATE_SHUTTING_DOWN, CI::STATE_TERMINATED].member?(instance.state)

    if params['metric_name'].blank?
      raise E::UnknownMetricName, "#{params['metric_name']}"
    end

    if params['params'].blank? || params['params'].is_a?(String)
      raise E::UnknownParams, "#{params['params']}"
    end

    if CA::RESOURCE_METRICS.include?(params['metric_name']) && params['evaluation_periods'].blank?
      raise E::UnknownEvaluationPeriods, "#{params['evaluation_periods']}"
    end

    if CA::LOG_METRICS.include?(params['metric_name']) && params['notification_periods'].blank?
      raise E::UnknownNotificationPeriods, "#{params['notification_periods']}"
    end

    alarm = M::Alarm.entry_new(@account) {|al|

      al.resource_id = params['resource_id']
      al.metric_name = params['metric_name']

      if params['display_name']
        al.display_name = params['display_name']
      end

      if params['description']
        al.description = params['description']
      end

      if params['enabled']
        if params['enabled'] == "true"
          al.enabled = 1
        else
          al.enabled = 0
        end
      else
        al.enabled = 1
      end

      if CA::RESOURCE_METRICS.include?(params['metric_name']) && params['evaluation_periods']
        al.evaluation_periods = params['evaluation_periods'].to_i
      end

      if CA::LOG_METRICS.include?(params['metric_name']) && params['notification_periods']
        al.notification_periods = params['notification_periods']
      end

      if params['params'] && params['params'].is_a?(Hash)
        save_params = {}
        if CA::LOG_METRICS.include?(params['metric_name'])
          save_params['tag'] = params['params']['tag']
          save_params['match_pattern'] = params['params']['match_pattern']
        elsif CA::RESOURCE_METRICS.include?(params['metric_name'])
          save_params['threshold'] = params['params']['threshold'].to_f
          save_params['comparison_operator'] = params['params']['comparison_operator']
        else
          raise E::UnknownMetricName, "#{params['metric_name']}"
        end

        al.params = save_params
      end

      if params[:ok_actions] || params[:alarm_actions] || params[:insufficient_data_actions]
        if CA::LOG_METRICS.include?(params[:metric_name])
          al.alarm_actions = params[:alarm_actions]
        elsif CA::RESOURCE_METRICS.include?(params[:metric_name])
          al.ok_actions = params[:ok_actions]
          al.alarm_actions = params[:alarm_actions]
          al.insufficient_data_actions = params[:insufficient_data_actions]
        end
      end

      raise E::InvalidParameter, al.errors.full_messages.first unless al.valid?
    }

    on_after_commit do
      i = find_by_uuid(:Instance, params['resource_id'])
      Dcmgr.messaging.submit(alarm_endpoint(alarm.metric_name, i.host_node.node_id), 'update_alarm', alarm.canonical_uuid)
    end

    respond_with(R::Alarm.new(alarm).generate)
  end

  delete '/:id' do
    al = find_by_uuid(:Alarm, params[:id])
    al = al.destroy

    on_after_commit do
      i = find_by_uuid(:Instance, al.resource_id)
      Dcmgr.messaging.submit(alarm_endpoint(al.metric_name, i.host_node.node_id), 'delete_alarm', al.canonical_uuid)
    end

    respond_with([al.canonical_uuid])
  end

  get '/:id' do
    al = find_by_uuid(:Alarm, params[:id])
    raise E::UnknownAlarm, params[:id] if al.nil?

    respond_with(R::Alarm.new(al).generate)
  end

  put '/:id' do
    al = find_by_uuid(:Alarm, params[:id])
    al.update_alarm do |v|
      if params[:display_name]
        al.display_name = params[:display_name]
      end

      if params[:description]
        al.description = params[:description]
      end

      if params[:enabled]
        if params[:enabled] == "true"
          al.enabled = 1
        else
          al.enabled = 0
          al.state = "init"
          al.state_timestamp = Time.now
        end
      end

      if params[:evaluation_periods] && CA::RESOURCE_METRICS.include?(al.metric_name)
        al.evaluation_periods = params[:evaluation_periods].to_i
      end

      if params[:notification_periods] && CA::LOG_METRICS.include?(al.metric_name)
        al.notification_periods = params[:notification_periods].to_i
      end

      if params['params'] && params['params'].is_a?(Hash)
        update_params = {}
        if al.is_log_alarm?
          update_params['tag'] = al.params['tag']
          if params['params']['match_pattern']
            update_params['match_pattern'] = params['params']['match_pattern']
          else
            update_params['match_pattern'] = al.params['match_pattern']
          end
        elsif al.is_metric_alarm?
          if params['params']['threshold']
            params['params']['threshold'] = params['params']['threshold'].to_f
          end

          ['threshold', 'comparison_operator'].each {|key|
            if params['params'][key]
              update_params[key] = params['params'][key]
            else
              update_params[key] = al.params[key]
            end
          }
        else
          raise E::UnknownMetricName, al.metric_name
        end
        al.params = update_params
      end
      raise E::InvalidParameter, al.errors.full_messages.first unless al.valid?
    end

    on_after_commit do
      i = find_by_uuid(:Instance, al.resource_id)
      Dcmgr.messaging.submit(alarm_endpoint(al.metric_name, i.host_node.node_id), 'update_alarm', al.canonical_uuid)
    end

    respond_with([al.canonical_uuid])
  end

  private
  def alarm_endpoint(metric_name, node_id)
    case metric_name
      when 'log'
        name = 'log-alarm-registry'
      else
        name = 'resource-alarm-registry'
    end
    "#{name}.#{node_id}"
  end

end
