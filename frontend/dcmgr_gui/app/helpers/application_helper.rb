module ApplicationHelper
  
  def li_link_to_current(name, controller_name, action_name)
    if current_page?(:controller => controller_name)
      str = '<li class="current">' + link_to(name, {:controller => controller_name, :action => action_name}) + '</li>'
    else
      str = '<li>' + link_to(name, {:controller => controller_name, :action => action_name}) + '</li>'
    end
    str.html_safe
  end
  
  def show_accounts
    User.account_name_with_uuid(@current_user.uuid)
  end
  
  def primary_account_id
    User.primary_account_id(@current_user.uuid)
  end

  def nl2br(text)
    text.gsub(/(<.*?>)/, '').gsub(/\n/, '<br />').html_safe
  end

  def user_last_login_at
    @current_user.last_login_at.utc.iso8601
  end

  def system_account?
    account_uuid = User.primary_account_id(@current_user.uuid)
    account_uuid == '00000000'
  end

  def accounts_with_prefix
    Account.all_accounts_with_prefix
  end  

end

