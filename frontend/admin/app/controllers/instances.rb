DcmgrAdmin.controllers :instances do

  set :views, "app/views"

  get :index do
    erb :"instances/index"
  end

  get '/:id' do
    erb :"instances/show"
  end

end
