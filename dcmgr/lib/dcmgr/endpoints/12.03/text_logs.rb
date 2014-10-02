# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/text_log'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/text_logs' do

  get do

    # If you want to provide to the user, it is much better to apply access restrictions.
    config = {
      :account_id => params[:account_id],
      :instance_id => params[:instance_id],
      :application_id => params[:application_id]
    }

    if params[:start_time].empty?
      time = Time.now.utc.iso8601
    else
      time = params[:start_time]
    end

    limit = params[:limit]
    text_log = Dcmgr::TextLog.new(log_storage, config)
    last_id = params[:id]

    if(last_id)
      config = {
        :time => time
      }
      ds = text_log.position_search(last_id, limit, config)
    else
      ds = text_log.timeseries_search(time, limit)
    end

    collection_respond_with(ds) do |ds|
      R::TextLogCollection.new(ds).generate
    end

  end

  get '/keys' do


    config = {
      :account_id => params[:account_id],
      :instance_id => params[:instance_id],
      :application_id => params[:application_id]
    }

    results = log_storage.get_keys

    respond_with([{
                :total => results.size,
                :results=> results
              }])
  end

  private
  def collection_respond_with(ds, &blk)
    results = blk.call(ds)
    respond_with([{
                    :total => results.size,
                    :start => params[:start] || 0,
                    :limit => params[:limit] || 0,
                    :results=> results
                  }])
  end

  def log_storage
    Dcmgr::Models::LogStorage.create(:cassandra, {
      :keyspace => Dcmgr::Configurations.dcmgr.cassandra_keyspace,
      :cf => Dcmgr::Configurations.dcmgr.cassandra_cf,
      :uri => Dcmgr::Configurations.dcmgr.cassandra_uri
    })
  end
end
