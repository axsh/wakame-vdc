class SessionsController < ApplicationController
  layout 'login'
  skip_before_filter :login_required
  
  def new
    @user =  Frontend::Models::User.new
  end
  
  def create
    user = Frontend::Models::User.authenticate(params[:login], params[:password])
    if user
      self.current_user = user
      redirect_back_or_default('/', :notice => "Logged in successfully")
    else
      # note_failed_signin
      @login       = params[:login]
      render :action => 'new'
    end
  end
  
  def destroy
    logout_killing_session!
    redirect_back_or_default('/', :notice => "You have been logged out.")
  end
end