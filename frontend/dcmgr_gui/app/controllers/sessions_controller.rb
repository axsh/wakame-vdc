class SessionsController < ApplicationController
  layout 'login'
  skip_before_filter :login_required
  
  def new
    @user =  User.new
  end
  
  def information
    render :layout => false
  end

  def create
    user = User.authenticate(params[:login], params[:password])
    @error_message = ''

    if user
      self.current_user = user
      user.update_last_login
      redirect_back_or_default('/', :notice => "Logged in successfully")
    else
      @error_message = I18n.t('error_message.sign_in')
      @login = params[:login]
      render :action => 'new'
    end
  end
  
  def destroy
    logout_killing_session!
    redirect_back_or_default('/', :notice => "You have been logged out.")
  end
end
