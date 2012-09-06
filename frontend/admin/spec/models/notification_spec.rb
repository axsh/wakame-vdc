require 'spec_helper'

describe "Notification Model" do
  let(:notification) { Notification.new }
  it 'can be created' do
    notification.should_not be_nil
  end
end
