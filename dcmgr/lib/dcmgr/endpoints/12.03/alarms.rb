# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/alarm'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/alarms' do

  C = Dcmgr::Constants::Alarm

  get do

    unless C::METRIC_NAMES.include?(params[:metric_name])
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

    unless C::METRIC_NAMES.include?(params[:metric_name])
      raise E::UnknownMetricName, "#{params[:metric_name]}"
    end

    alarm = M::Alarm.entry_new(@account) {|al|

      al.resource_id = params[:resource_id]
      al.metric_name = params[:metric_name]

      if params[:display_name]
        al.display_name = params[:display_name]
      end

      if params[:description]
        al.description = params[:description]
      end

      if params['params']
        save_params = {}
        if params[:metric_name] == 'log'
          save_params['label'] = params['params']['label']
          save_params['match_pattern'] = params['params']['match_pattern']
        else
          save_params['period'] = params['params']['period'].to_i
          save_params['statistics'] = params['params']['statistics']
          save_params['threshold'] = params['params']['threshold'].to_f
          save_params['unit'] = params['params']['unit']
          save_params['comparison_operator'] = params['params']['comparison_operator']
        end
        al.params = save_params
      end
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
end
