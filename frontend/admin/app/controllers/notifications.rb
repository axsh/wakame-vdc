DcmgrAdmin.controllers :notifications do

  set :views, "app/views"

  get :index do
   erb :"notifications/index"
  end

  get :new do
    if flash[:complete]
      erb :"notifications/new_complete"
    else
      erb :"notifications/new"
    end
  end

  get '/:id' do
   erb :"notifications/show"
  end

  post '/' do
    @notification = Notification.new
    @notification.users = params[:users]
    @notification.title = params[:title]
    @notification.publish_date_to = Time.iso8601(params[:publish_date_to])
    @notification.publish_date_from = Time.iso8601(params[:publish_date_from])
    @notification.article = params[:article]

    if @notification.valid?
      if params[:confirm] != "1"
        erb :"notifications/confirm"
      else
        @notification.save
        flash[:complete] = 'Create notification'
        redirect '/notifications/new'
      end
    else
      erb :"notifications/new"
    end
  end

end
