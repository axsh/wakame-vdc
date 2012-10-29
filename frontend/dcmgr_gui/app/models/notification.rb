# -*- coding: utf-8 -*-

class Notification < BaseNew
  taggable 'n'
  with_timestamps
  plugin LogicalDelete

  DISTRIBUTION_TYPE = ['all', 'any'].freeze

  subset(:alives, {:deleted_at => nil})
  one_to_many :notification_users, :class=>NotificationUser

  def_dataset_method(:notifications) do |distribution='all', user_id=nil|
    if ['any', 'merged'].member? distribution
      case distribution
        when 'any'
          if user_id
            dataset = self.filter("`notifications`.`id` IN ? and `notifications`.`distribution` = ?", NotificationUser.filter(:user_id => user_id).select(:notification_id), 'any')
          else
            dataset = self.filter("`notifications`.`distribution` = ?", 'any')
          end
        when 'merged'
          dataset = self.filter("`notifications`.`id` IN ? or `notifications`.`distribution` = ?", NotificationUser.filter(:user_id => user_id).select(:notification_id), 'all')
      end
    else
      dataset = self.filter(:distribution => 'all')
    end
    timenow = Time.now.utc
    dataset.filter("`notifications`.`display_begin_at` <= ?", timenow).filter("`notifications`.`display_end_at` >= ?", timenow).order(:updated_at.desc)
  end

  def validate
    super
    errors.add(:distribution, 'Invalided distribution type') if !DISTRIBUTION_TYPE.member? distribution
    errors.add(:title, 'Cannot be empty') if !title || title.empty?
  end

end
