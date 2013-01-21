# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class QueuedJob < Dcmgr::Endpoints::ResponseGenerator
    def initialize(queued_job)
      raise ArgumentError if !queued_job.is_a?(Dcmgr::Models::QueuedJob)
      @queued_job = queued_job
    end

    def generate()
      @queued_job.instance_exec {
        to_hash.merge(:id=>canonical_uuid)
      }
    end
  end

  class QueuedJobCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        QueuedJob.new(i).generate
      }
    end
  end
end
