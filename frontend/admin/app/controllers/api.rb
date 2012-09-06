DcmgrAdmin.controllers :api do
  disable :layout

  get :notifications, :provides => :json do
    limit = params['limit'].nil? ? 10 : params['limit'].to_i
    start = params['start'].nil? ? 0 : params['start'].to_i
    @notifications = Notification.limit(limit, start).all
    results = []
    @notifications.each {|n|
      results << {
        :id => n.id,
        :title => n.title,
        :publish_date_from => n.publish_date_from,
        :publish_date_to => n.publish_date_to,
        :users => n.users
      }
    }
    h = {
      :count => Notification.count,
      :results => results
    }
    render h
  end

  delete :notifications, :provides => :json do
    @notification = Notification.find({:id => params[:id]})
    @notification.destroy
    h = {
      :results => true
    }
    render h
  end

end
