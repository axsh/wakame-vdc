class HomeController < ApplicationController
  def index
    params[:limit] ||=5
    @notifications = Notification.notifications('merged', current_user.id).limit(params[:limit].to_i)
  end
end
