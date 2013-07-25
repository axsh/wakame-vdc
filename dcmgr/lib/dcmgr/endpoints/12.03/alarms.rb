# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/alarm'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/alarms' do

  CA = Dcmgr::Constants::Alarm

  get do

    unless CA::SUPPORT_METRICS.include?(params[:metric_name])
      raise E::UnknownMetricName, "#{params[:metric_name]}"
    end

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
    unless params[:resource_id]
      raise E::UnknownResourceID, "#{params[:resource_id]}"
    end

    unless params['params']
      raise E::UnknownParams, params["params"]
    end

    alarm = M::Alarm.entry_new(@account) {|al|

      al.resource_id = params[:resource_id]

      if params[:display_name]
        al.display_name = params[:display_name]
      end

      if params[:description]
        al.description = params[:description]
      end

      if params[:enabled]
        al.enabled = params[:enabled].to_i
      end

      if params[:evaluation_periods]
        al.evaluation_periods = params[:evaluation_periods].to_i
      end

      if params['params'] && params['params'].is_a?(Hash)
        save_params = {}
        if CA::LOG_METRICS.include?(params['metric_name'])
          save_params['label'] = params['params']['label']
          save_params['match_pattern'] = params['params']['match_pattern']
        elsif CA::RESOURCE_METRICS.include?(params['metric_name'])
          save_params['statistics'] = params['params']['statistics']
          save_params['threshold'] = params['params']['threshold'].to_f
          save_params['comparison_operator'] = params['params']['comparison_operator']
        else
          raise E::UnknownMetricName, "#{params['metric_name']}"
        end

        al.metric_name = params[:metric_name]

        al.params = save_params
      end

      raise E::InvalidParameter, al.errors.full_messages.first unless al.valid?
    }

    respond_with(R::Alarm.new(alarm).generate)
  end

  delete '/:id' do
    al = find_by_uuid(:Alarm, params[:id])
    al = al.destroy

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
        al.enabled = params[:enabled].to_i
      end

      if params[:evaluation_periods]
        al.evaluation_periods = params[:evaluation_periods].to_i
      end

      if params['params'] && params['params'].is_a?(Hash)
        update_params = {}
        if al.is_log_alarm?
          update_params['label'] = al.params['label']
          if params['params']['match_pattern']
            update_params['match_pattern'] = params['params']['match_pattern']
          else
            update_params['match_pattern'] = al.params['match_pattern']
          end
        elsif al.is_metric_alarm?
          if params['params']['threshold']
            params['params']['threshold'] = params['params']['threshold'].to_f
          end

          ['threshold', 'statistics', 'comparison_operator'].each {|key|
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

    respond_with([al.canonical_uuid])
  end

end
