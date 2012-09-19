DcmgrAdmin.controllers :api do
  require 'spoof_token_authentication'
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

  get '/notifications/:id', :provides => :json do

    @notification = Notification.find(:id => params[:id])

    result = {
      :id => @notification.id,
      :title => @notification.title,
      :publish_date_from => @notification.publish_date_from,
      :publish_date_to => @notification.publish_date_to,
      :users => @notification.users,
      :article => @notification.article
    }

    h = {
      :count => 1,
      :result => result
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

  get :generate_token, :provides => :json do
    timestamp = Time.now.to_s
    token = SpoofTokenAuthentication.generate(params[:id], timestamp)
    results = {
      :token => token,
      :timestamp => timestamp,
      :user_id => params[:id]
    }
    h = {:results =>results}
    render h
  end
end
