require 'sequel'

module Dcmgr
  module Models
    class AccountLog < Sequel::Model
      many_to_one :account
      many_to_one :user, :left_primary_key=>:user_id

      def before_create
        super
        self.created_at = Time.now unless self.created_at
      end

      def validate
        errors.add(:account, "can't empty") unless (self.account or self.account_id)
        errors.add(:tareget_uuid, "can't empty") unless self.target_uuid
        errors.add(:target_type, "can't empty") unless self.target_type
        errors.add(:usage_value, "can't empty") unless self.usage_value
      end

      def self.last_date(year, month)
        next_year = month == 12? year + 1: year
        next_month = month == 12? 1: month + 1
        t = Time.local(next_year, next_month, 1)
        if t > (now = Time.now)
          now
        else
          t
        end
      end

      def self.generate(year, month)
        clear(year, month)

        instances = {}
        instance_uuids(year, month).each{|l|
          logs = instance_logs(year, month, l.target_uuid).map{|i|
            {:action=>i.action, :date=>i.created_at}
          }
          status = "terminate"
          usage_sec = 0.0
          start = nil

          logs.each{|lg|
            p lg
            if lg[:action] == "run"
              start = lg[:date]
            elsif lg[:action] == "terminate"

              usage_sec += lg[:date] - start
            end
          }

          if logs.last[:action] == "run"
            p "lst"
            p last_date(year, month)
            p logs.last[:date]
            p usage_sec
            usage_sec += last_date(year, month) - logs.last[:date]
            p usage_sec
          end

          create(:target_date=>Time.local(year, month),
                 :account_id=>l.account_id,
                 :target_uuid=>l.target_uuid,
                 :target_type=>TagMapping::TYPE_INSTANCE,
                 :usage_value=>(usage_sec / 60).ceil)
        }
      end

      def self.instance_uuids(year, month)
        Log.filter("YEAR(created_at) = ? AND MONTH(created_at) = ?" +
                   " AND target_uuid LIKE 'I-%'",
                   year, month).group(:target_uuid).all
      end

      def self.instance_logs(year, month, uuid)
        Log.filter("YEAR(created_at) = ? AND MONTH(created_at) = ?" +
                   " AND target_uuid = ?",
                   year, month, uuid).order(:target_uuid).all
      end

      def self.clear(year, month)
        filter('YEAR(target_date) = ? AND MONTH(target_date) = ?',
               year, month).tap{|o| p o.sql }.delete
      end
    end
  end
end
