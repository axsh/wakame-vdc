class ResourceController < ApplicationController
  before_filter :system_manager?

  def index
    account_uuid = User.primary_account_id(@current_user.uuid)
  end
end
