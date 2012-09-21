class Notification < Sequel::Model

  subset(:alives, {:deleted_at => nil})

  def validate
    super
    errors.add(:title, 'cannot be empty') if !title || title.empty?
  end

  def before_create
    return false if super == false
    self.created_at = Time.now
  end

  def before_save
    return false if super == false
    self.updated_at = Time.now
  end

  def before_destroy
    return false if super == false
    self.deleted_at = Time.now
  end

end
