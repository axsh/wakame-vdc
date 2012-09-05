DcmgrAdmin.controllers :users do

  get :index do
    erb :"users/index"
  end

  get '/:id' do
    erb :"users/show"
  end

end
