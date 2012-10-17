DcmgrAdmin.controllers :host_nodes do

  get :index do
    erb :"host_nodes/index"
  end

  get "/:id" do
    erb :"host_nodes/show"
  end
end
