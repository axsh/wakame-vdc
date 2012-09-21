DcmgrAdmin.controllers :api do
  require 'spoof_token_authentication'
  disable :layout

  get :notifications, :provides => :json do
    limit = params['limit'].nil? ? 10 : params['limit'].to_i
    start = params['start'].nil? ? 0 : params['start'].to_i
    @notifications = Notification.limit(limit, start).alives.all
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

    @notification = Notification.filter(:id => params[:id]).alives.first
    if @notification.nil?
      h = { :result => '' }
      return render h
    end

    h = {
      :count => 1,
      :result => @notification.to_hash
    }
    render h
  end

  delete '/notifications/:id', :provides => :json do
    @notification = Notification.filter({:id => params[:id]}).alives.first
    if @notification.nil?
      h = { :result => '' }
      return render h
    end

    @notification.deleted_at = Time.now
    @notification.save_changes

    h = {
      :result => @notification.to_hash
    }
    render h
  end

  post :notifications, :provides => :json do
    @notification = Notification.new
    @notification.users = params[:users]
    @notification.title = params[:title]
    @notification.publish_date_to = Time.iso8601(params[:publish_date_to])
    @notification.publish_date_from = Time.iso8601(params[:publish_date_from])
    @notification.article = params[:article]
    if @notification.valid?
      @notification.save
      h = {
       :result => @notification.to_hash
      }
    else
      h = {
       :result => {}
      }
    end
    render h
  end

  put '/notifications/:id', :provides => :json do

    @notification = Notification.filter(:id => params[:id]).alives.first
    if @notification.nil?
      h = { :result => '' }
      return render h
    end

    if params[:title]
      @notification.title = params[:title]
    end

    if params[:users]
      @notification.users = params[:users]
    end


    if params[:publish_date_to]
      @notification.publish_date_to = Time.iso8601(params[:publish_date_to])
    end

    if params[:publish_date_from]
      @notification.publish_date_from = Time.iso8601(params[:publish_date_from])
    end

    if params[:article]
      @notification.article = params[:article]
    end

    if @notification.valid?
      @notification.save_changes
    end

    h = {
      :result => @notification.to_hash
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
