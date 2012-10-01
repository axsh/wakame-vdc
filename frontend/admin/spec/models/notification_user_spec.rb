require 'spec_helper'

describe "NotificationUser Model" do
  let(:notification_user) { NotificationUser.new }
  it 'can be created' do
    notification_user.should_not be_nil
  end
end
