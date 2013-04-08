# -*- coding: utf-8 -*-

module Dcmgr
  class TextLog

    def initialize(storage, config)
      raise 'Invalid log storege' unless storage.is_a?(Dcmgr::Models::LogStorage::Base)

      @storage = storage
      @account_id = config[:account_id]
      @instance_id = config[:instance_id]
      @application_id = config[:application_id]
    end

    def timeseries_search(time, limit)
      res = @storage.timeseries_search(self.path, time, limit)
      res.collect {|key, value| {
        :id => key.to_guid,
        :message =>  value
      }}
    end

    def position_search(position_id, limit, options={})
      limit = limit.to_i
      limit = limit + 1 if limit > 0
      res = @storage.position_search(self.path, position_id, limit, options)
      res.shift if limit > 1 && res.size > 1

      res.collect {|key, value| {
        :id => key.to_guid,
        :message =>  value
      }}
    end

    def path
      @storage.path(@account_id, @instance_id, @application_id)
    end

    def storage
      @storage
    end

    def get_keys
      @storage.get_keys()
    end
  end
end