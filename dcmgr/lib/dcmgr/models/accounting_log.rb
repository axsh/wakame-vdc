# -*- coding: utf-8 -*-

module Dcmgr::Models
  class AccountingLog < BaseNew
    plugin :timestamps

    def self.record(target_class, changed_column)
      hist_rec = {
        :uuid => target_class.canonical_uuid,
        :account_id => target_class.account_id,
        :resource_type => target_class.model.to_s.sub('Dcmgr::Models::', ''),
        :event_type => changed_column.to_s,
        :created_at => Time.now
      }

      coldef = target_class.db_schema[changed_column]
      case coldef[:type]
        when :text,:blob
          hist_rec[:blob_value]= (target_class.new? ? (target_class[changed_column] || coldef[:default]) : target_class[changed_column])
        when :integer
          hist_rec[:int_value]= (target_class.new? ? (target_class[changed_column] || coldef[:default]) : target_class[changed_column])
        else
          hist_rec[:vchar_value]=(target_class.new? ? (target_class[changed_column] || coldef[:default]) : target_class[changed_column])
      end

      self.dataset.insert(hist_rec)
    end

  end
end
