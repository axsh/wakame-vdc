# -*- coding: utf-8 -*-
module Dcmgr::Models

  class Alarm < AccountResource
    taggable 'alm'
    subset(:alives, {:deleted_at => nil})
    plugin :serialization, :yaml, :params
    include Dcmgr::Constants::Alarm

    def validate
      super

      if evaluation_periods < 0
        errors.add(:evaluation_periods, "it must have digit more than zero")
      end

      if self.is_log_alarm?
        begin
          if params["match_pattern"].blank?
            errors.add(:match_pattern, "Unknown value")
          else
            Regexp.compile(Regexp.escape(params["match_pattern"]))
          end
        rescue => e
          errors.add(:match_pattern, "Invalid pattern")
        end

        unless /^[0-9a-z.]+$/ =~ params['label']
          errors.add(:label, "Invalid format")
        end

      elsif self.is_metric_alarm?
        if params["threshold"] < 0
          errors.add(:threshold, "it must have digit more than zero")
        end

        unless SUPPORT_COMPARISON_OPERATOR.include?(params['comparison_operator'])
          errors.add(:comparison_operator, "it must have #{SUPPORT_COMPARISON_OPERATOR.join(',')}")
        end
      else
        errors.add(:metric_name, 'Unknown metric name')
      end
    end

    def self.entry_new(account, &blk)
      al = self.new
      al.account_id = (account.is_a?(Account) ? account.canonical_uuid : account.to_s)
      blk.call(al)
      al.save
    end

    def update_alarm(&blk)
      blk.call(self)
      self.save_changes
    end

    def is_log_alarm?
      LOG_METRICS.include?(metric_name)
    end

    def is_metric_alarm?
      RESOURCE_METRICS.include?(metric_name)
    end

    def to_hash
      h = super
      h
    end

    private
    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

    def before_save
      super
      if is_log_alarm?
        match_pattern = Regexp.escape(params['match_pattern'])
      end
    end
  end
end
