#-
# Copyright (c) 2010 axsh co., LTD.
# All rights reserved.
#
# Author: Takahisa Kamiya
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

require 'WakameWebAPI'

use Rack::Session::Cookie,
# :domain => '',
:key => 'dcmgr-gui.session',
:path => '/',
#:expire_after => 1.minutes,
:secret       => 'dcmgr-gui'

helpers do
  def auth_ok?(name, pw)
    debug_log name
    debug_log pw
    rtn = false
    begin
      User.login(name,pw)
#     user = User.find(:all,:params=>{:name=>name,:password=>pw})
      user = User.find(:myself)
rtn = true
=begin
      if user.length == 1
        session[:login_user_obj] = user
        rtn = true
      else
        debug_log "not find user."
      end
=end
    rescue => err
      debug_log err
    end
    rtn
  end

 def login(login_select)
   @selector = login_select
   if auth_ok?(params['id'], params['pw'])
     session[:login_user] = login_select
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
   session.delete(:login_user)
   session.delete(:login_user_obj)
   if session[:log_in_path]
     lg_path = session[:log_in_path]
     session.delete(:log_in_path)
     redirect lg_path
   end
 end

 def need_auth login_select
   @selector = login_select
   unless session[:login_user] && session[:login_id] && session[:login_pw]
     erb :login
   else
     if session[:login_user] == login_select && auth_ok?(session[:login_id], session[:login_pw])
       yield
     else
       erb :login
     end
   end
 end
end
