class AccountsController < ApplicationController
  def switch
    account_uuid = params[:accounts][:account_uuid]

    user = Frontend::Models::User.find(:uuid => @current_user.uuid)
    user.primary_account_id = account_uuid
    user.save

    redirect_to :root
  end
  
  def index
    
  end
end
