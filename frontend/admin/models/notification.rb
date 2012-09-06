class Notification < Sequel::Model
  def validate
    super
    errors.add(:title, 'cannot be empty') if !title || title.empty?
  end
end
