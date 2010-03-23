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
        errors.add(:user, "can't empty") unless (self.user or self.user_id)
      end

      def self.generate(year, month)
        clear(year, month)

        instances = {}
        instance_uuids(year, month).each{|l|
          logs = instance_logs(year, month, l.target_uuid).map{|i|
            {:action=>i.action, :date=>i.created_at}
          }
          status = "terminate"
          min = 0.0
          start = nil
          logs.each{|lg|
            if lg[:action] == "run"
              start = lg[:date]
            elsif lg[:action] == "terminate"
              min += (lg[:date] - start) / 1000
            end
          }
          create(:target_date=>Time.gm(year, month),
                 :user_id=>l.user_id,
                 :account_id=>l.account_id,
                 :target_uuid=>l.target_uuid,
                 :use_minutes=>min)
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
               year, month).delete
      end
    end
  end
end
