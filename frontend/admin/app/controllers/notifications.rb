DcmgrAdmin.controllers :notifications do

  set :views, "app/views"

  get :index do
   @message = flash[:message]
   erb :"notifications/index"
  end

  get :new do
    erb :"notifications/new"
  end

  get '/:id' do
   erb :"notifications/show"
  end

  post '/confirm' do
   erb :"notifications/confirm"
  end

  get '/:id/edit' do
   erb :"notifications/new"
  end

end
