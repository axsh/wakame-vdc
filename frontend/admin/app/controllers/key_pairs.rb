DcmgrAdmin.controllers :key_pairs do

  get "/:id" do
    erb :"key_pairs/show"
  end

end
