class Notification < Sequel::Model

  DISTRIBUTION_TYPE = ['all', 'any'].freeze

  subset(:alives, {:deleted_at => nil})

  def_dataset_method(:notifications) do |distribution='all', user_id=''|
    if ['any', 'merged'].member? distribution
      case distribution
        when 'any'
          dataset = self.filter("`notifications`.`id` IN ? and `notifications`.`distribution` = ?", NotificationUser.filter(:user_id => user_id).select(:notification_id), 'any')
        when 'merged'
          dataset = self.filter("`notifications`.`id` IN ? or `notifications`.`distribution` = ?", NotificationUser.filter(:user_id => user_id).select(:notification_id), 'all')
      end
    else
      dataset = self.filter(:distribution => 'all')
    end
    dataset.order(:updated_at.desc)
  end


  def validate
    super
    errors.add(:distribution, 'Invalided distribution type') if !DISTRIBUTION_TYPE.member? distribution
    errors.add(:title, 'Cannot be empty') if !title || title.empty?
  end

  def to_hash()
    self.values.dup
  end

  def before_create
    super
    return false if super == false
    self.created_at = Time.now
  end

  def before_save
    super
    return false if super == false
    self.updated_at = Time.now
  end

  def before_destroy
    super
    return false if super == false
    self.deleted_at = Time.now
  end

end
