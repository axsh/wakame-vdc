# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Report < Dcmgr::Endpoints::ResponseGenerator
    def initialize(report)
      raise ArgumentError if !report.is_a?(Dcmgr::Models::AccountingLog)
      @report = report
    end

    def generate()
      @report.instance_exec {
        h = {
          :uuid => self.uuid,
          :resource_type => self.resource_type,
          :event_type => self.event_type,
          :value => case self.event_type
                      when 'state'
                        self.vchar_value
                      when 'memory_size', 'cpu_cores', 'size'
                        self.int_value
                    end,
          :time => self.created_at
        }
        h
      }

    end
  end

  class ReportCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        Report.new(i).generate
      }
    end
  end
end
