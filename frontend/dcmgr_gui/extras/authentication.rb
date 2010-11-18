# Copyright (c) 2010 David Heinemeier Hansson
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#
# restful_authentication
# overwrite lib/authenticated_system.rb 
#

module Authentication
  #overwrite
  def current_user
    @current_user ||= login_from_session unless @current_user == false
  end

  #overwrite
  def current_user=(new_user)
    session[:uuid] = new_user ? new_user.uuid : nil
    @current_user = new_user || false
  end
    
  def current_account
    @current_account ||= Account.find(:uuid => self.current_user.primary_account_id)
  end
  
  #overwrite
  def login_from_session
    self.current_user = User.get_user(session[:uuid]) if session[:uuid]
  end

  def logout_killing_session!
    logout_keeping_session!
    reset_session
  end

  def logout_keeping_session!
    @current_user = false
    @current_account = false
    session[:uuid] = nil
  end

  def logged_in?
    !!current_user
  end
  
  def login_required
    uuid = 'a-'+current_user.primary_account_id
    ActiveResource::Connection.set_vdc_account_uuid(uuid)
    authorized? || access_denied
  end
  
  def authorized?(action = action_name, resource = nil)
    logged_in?
  end
  
  #overwrite
  def access_denied
    respond_to do |format|
      format.html do
        store_location
        redirect_to new_session_path
      end
    end
  end
  
  def store_location
    session[:return_to] = request.request_uri
  end
  
  def redirect_back_or_default(default, options = {})
    redirect_to((session[:return_to] || default), options)
    session[:return_to] = nil
  end
end