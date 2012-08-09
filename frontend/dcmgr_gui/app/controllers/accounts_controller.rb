class AccountsController < ApplicationController
  def switch
    @current_user.tap { |u|
      u.primary_account_id = params[:accounts][:account_uuid]
      u.save_changes
    }

    redirect_to :root
  end
  
  def index

  end

  def update_settings
    account = params[:account]
    if account
      
      setting_params = {
        :time_zone => account[:time_zone],
        :locale => account[:locale],
      }

      @current_user.update_settings(setting_params)
    end
    redirect_to :action => 'index'
  end

  def password
    @error_message = ''
    if request.get?
      #nop
    elsif request.post?
      password =  params[:password]
      new_password = params[:new_password]
      confirm_password = params[:confirm_password]
      unless new_password == confirm_password
        @error_message = I18n.t('error_message.change_password1')
        return true 
      end

      user = User.find(:uuid => @current_user.uuid, :password => User.encrypt_password(password))
      if user
        user.password = User.encrypt_password(new_password)
        user.save_changes
        redirect_to :action => 'index'
      else
        @error_message = I18n.t('error_message.change_password2')
      end
    end
  end

  def usage
    catch_error do
      current_usage = Hijiki::DcmgrResource::Account.find(current_account.canonical_uuid).usage
      usage_quota = Hash[*current_account.account_quota.map{|q| [q.quota_type, q.quota_value]}.flatten]

      res_usage = {}
      current_usage.each { |k, v|
        res_usage[k]={:current=>v}
        res_usage[k][:quota]=usage_quota[k] if usage_quota[k]
      }
      render :json => res_usage
    end
  end
end
