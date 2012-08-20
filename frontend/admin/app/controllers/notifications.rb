DcmgrAdmin.controllers :notifications do

  set :views, "app/views"

  get :index do
    erb :"notifications/index"
  end

  get :show do
    erb :"notifications/show"
  end

  get :new do
    erb :"notifications/new"
  end

  get :edit do
    erb :"notifications/edit"
  end

  put :update do
  end

  post :create do
  end
  
  delete :destroy do
  end

end
