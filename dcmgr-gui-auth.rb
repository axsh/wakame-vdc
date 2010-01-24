require 'WakameWebAPI'

use Rack::Session::Cookie,
# :domain => '',
:key => 'dcmgr-gui.session',
:path => '/',
#:expire_after => 1.minutes,
:secret       => 'dcmgr-gui'

helpers do
  def auth_ok?(id, pw)
    rtn = true
    begin
      User.login(id,pw)
      User.find(:all)
    rescue => err
      rtn = false
    end
    rtn
  end

 def login(login_select)
   @selector = login_select
   if auth_ok?(params['id'], params['pw'])
     session[:login_id] = params['id']
     session[:login_pw] = params['pw']
     session[:log_in_path] = "/"+login_select+"/login"
     redirect "/"+login_select+"/"
   else
     erb :login
   end
 end

 def logout
   session.delete(:id)
   session.delete(:pw)
   if session[:log_in_path]
     lg_path = session[:log_in_path]
     session.delete(:log_in_path)
     redirect lg_path
   end
 end

 def need_auth login_select
   @selector = login_select
   unless session[:login_id] && session[:login_pw]
     erb :login
   else
     if auth_ok?(session[:login_id], session[:login_pw])
       yield
     else
       erb :login
     end
   end
 end
end
