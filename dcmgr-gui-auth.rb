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
     redirect "/"+login_select+"/"
   else
     erb :login
   end
 end

 def logout login_path
   session.delete(:login)
   redirect login_path
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
