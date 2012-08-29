class SessionsController < ApplicationController
  require 'base64'
  require 'openssl'
  layout 'login'
  skip_before_filter :login_required
  before_filter :authenticate, :only => [:new]

  def new
    @user =  User.new
  end
  
  def information
    render :layout => false
  end

  def create
    @error_message = ''
    if params[:login].blank? || params[:password].blank?
      @error_message = I18n.t('error_message.not_entered')
      @login = params[:login]
      return render :action => 'new'
    end
    user = User.authenticate(params[:login], params[:password])

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

  private
  def authenticate
    if params[:token]
      if params[:token] == Base64.encode64("#{OpenSSL::HMAC.digest('sha1', params[:user_id], DcmgrGui::Application.config.authorized_token)}")
        user = User.find(:uuid => User.trim_uuid(params[:user_id]))
        if user
          self.current_user = user
          user.update_last_login
          redirect_back_or_default('/', :notice => "Logged in successfully")
        else
          @error_message = I18n.t('error_message.sign_in')
        end
      else
        render :status=>403, :text=>"Authentication Failed"
        return false
      end
    end
  end
end
