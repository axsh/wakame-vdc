DcmgrAdmin.controllers :machine_images do

  get '/:id' do
    erb :"machine_images/show"
  end

end
