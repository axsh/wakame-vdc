DcmgrAdmin.controllers :ssh_key_pairs do

  get "/:id" do
    erb :"ssh_key_pairs/show"
  end

end
