DcmgrAdmin.controllers :load_balancers do

  set :views, "app/views"

  get :index do
    erb :"load_balancers/index"
  end

  get '/:id' do
    erb :"load_balancers/show"
  end

end
