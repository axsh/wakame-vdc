DcmgrAdmin.controllers :ssh_key_pairs do

  get "/:id" do
    erb :"key_pairs/show"
  end

end
