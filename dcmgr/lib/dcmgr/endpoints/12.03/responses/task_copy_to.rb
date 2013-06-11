# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class TaskCopyTo < Dcmgr::Endpoints::ResponseGenerator
    def initialize(job)
      raise ArgumentError, "#{Hash.to_s} is expected but #{job.class.to_s}" if !job.is_a?(Hash)
      @job = job
    end

    def generate()
      {
        :uuid => @job[:uuid],
        :created_at => @job[:created_at],
      }
    end
  end
end
