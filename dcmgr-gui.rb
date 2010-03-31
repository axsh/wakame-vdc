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

require 'sinatra'
require 'erb'
require 'client'
require 'parsedate'
require 'date'
require 'resource_manager'
require 'define'

def logger
  require 'logger'
  ::Logger.new(STDERR)
end

def debug_log(msg)
  logger.debug(msg)
end

# Shortcut for the AR client classes.
include Dcmgr::Client

configure do
  load 'dcmgr-gui.conf'
end

before do
  if session[:user_uuid].nil?
    next if request.path_info == '/center/login' || request.path_info == '/client/login'
    # force to show login page.
    redirect '/client/login'
    next
  else
    Dcmgr::Client::Base.user_uuid = session[:user_uuid]
  end
end

get '/' do
  'startup dcmgr-gui'
#  erb :index
end

not_found do
 debug_log "not found"
 "not found"
end

#################################
# for login
get '/center/' do
  erb :center
end
get '/center/login' do
  erb :login_center
end
post '/center/login' do
  authres = Dcmgr::Client::FrontendServiceUser.get(:authorize, :user=>params[:id], :password=>params[:pw])
  if authres
    session[:user_uuid] = authres['id']
    redirect '/center/'
    next
  else
    erb :login_center
  end
end
get '/client/' do
  erb :client
end
get '/client/login' do
  erb :login_client
end
post '/client/login' do
  authres = Dcmgr::Client::FrontendServiceUser.get(:authorize, :user=>params[:id], :password=>params[:pw])
  if authres
    session[:user_uuid] = authres['id']
    redirect '/client/'
    next
  else
    erb :login_client
  end
end
get '/logout' do
  session[:user_uuid] = nil
  redirect '/client/'
end
#################################

get '/user-name' do
  session[:login_id]
end

post '/account-create' do
  name = params[:nm]
  cdate = params[:cn]
  enable = params[:en]
  memo = params[:mm]
  rtn = {"success" => false}
  begin
    Dcmgr::Client::Account.create(:name=>name,
                   :enable=>enable,
                   :memo=>memo,
                   :contract_at=>cdate)
    rtn['success'] = true
  end
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/account-save' do
  rtn = {"success" => false}
  begin
    account = Account.find(params[:id])
    account.name = params[:nm]
    account.enable = params[:en]
    account.memo = params[:mm]
    # ary = ParseDate::parsedate(params[:cn])
    # account.contract_at = Time::local(*ary[0..-3]) //todo
    account.save
    rtn['success'] = true
  end
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/account-search' do 
  id = params[:id]
  nm = params[:nm]
  en = params[:en]
  cn = params[:cn]

  rtn = {'success'=>false,'totalCount'=>0,'rows'=>[]}
  accountList = nil
  begin
    fromDate = nil;
    toDate = nil;
    if cn.length > 0
      ary = ParseDate::parsedate(cn)
      fromDate = Time::local(*ary[0..-3])
      toDate = fromDate + 3600*24
    end

    acArg = Hash.new()
    acPrm = Hash.new()
    if id.length > 0
      acPrm.store(:id,id)
    else
      if cn.length > 0
	    acPrm.store(:contract_at,[fromDate,toDate])
      end
      if nm.length > 0
        acPrm.store(:name,nm)
      end
      if en == "1"
        acPrm.store(:enable,true)
      elsif en == "2"
        acPrm.store(:enable,false)
      end
    end
    if acPrm.length==0
      accountList = Account.find(:all)
    else
      acArg.store(:params,acPrm)
      accountList = Account.find(:all,acArg)
    end

    if accountList != nil
      rtn['success'] = true
      rtn['totalCount'] = accountList.length
      accountList.each{|index|
        rows = Hash::new
        rows.store('id',index.id)
        rows.store('nm',index.name)
        rows.store('rg',index.created_at)
        rows.store('cn',index.contract_at)
        rows.store('en',index.enable)
        rows.store('mm',index.memo)
        rtn['rows'].push(rows)
      }
    end
  end
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/account-remove' do
  id = params[:id]
  rtn = {"success" => false}
  begin
    account = Account.find(id)
    account.destroy
    rtn = {"success" => true}
  end
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/account-list' do
  rtn = {"success" => false,'totalCount'=>0,'rows'=>[]}
  begin
    accountList = Account.find(:all)
    rtn['success'] = true
    rtn['totalCount'] = accountList.length
    accountList.each{|index|
      rows = Hash::new
      rows.store('id',index.id)
      rows.store('nm',index.name)
      rows.store('rg',index.created_at)
      rows.store('cn',index.contract_at)
      rows.store('en',index.enable)
      rows.store('mm',index.memo)
      rtn['rows'].push(rows)
    }
  end
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/instance-list' do
  instanceList = Instance.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[] }
  rtn['totalCount'] = instanceList.length
  instanceList.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
    rows.store('od',index.user)
    rows.store('wd',index.image_storage)
    rows.store('st',@@inStatus[index.status.to_s])
    rows.store('ip',index.ip)
    type = "other"
    @@instanceType.each do |key,value|
      if value[0]==index.need_cpus.to_i
        if value[1]==index.need_cpu_mhz.to_i
          if value[2]==index.need_memory.to_i
            type = key
            break
          end
        end
      end
    end
    rows.store('tp',type)
    rtn['rows'].push(rows)
  }
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/instance-detail-list' do
  instanceList = Instance.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[] }
  rtn['totalCount'] = instanceList.length
  instanceList.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
    rows.store('sd','')				# physicalhost ID
    rows.store('ad',index.account)
    rows.store('ud',index.user)
    rows.store('wd',index.image_storage)
    rows.store('st',@@inStatus[index.status.to_s])
    rows.store('ip',index.ip)
    type = "other"
    @@instanceType.each do |key,value|
      if value[0]==index.need_cpus.to_i
        if value[1]==index.need_cpu_mhz.to_i
          if value[2]==index.need_memory.to_i
            type = key
            break
          end
        end
      end
    end
    rows.store('tp',type)
    rows.store('sv','')				# image name (from index.image_storage)
    rtn['rows'].push(rows)
  }
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-create' do
  id = params[:id]
  wd = params[:wd]
  tp = params[:tp]
  cpus=@@instanceType[tp][0]
  cpu_mhz=@@instanceType[tp][1]
  memory=@@instanceType[tp][2]
  instance = Instance.create(
               :account=>id,
               :wid=>wd,
               :need_cpus=>cpus,
               :need_cpu_mhz=>cpu_mhz,
               :need_memory=>memory,
               :image_storage=>wd)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-reboot' do
  id = params[:id]
  instance = Instance.find(id)
  instance.put(:reboot)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-save' do
  id = params[:id]
  instance = Instance.find(id)
  instance.put(:save)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-terminate' do
  id = params[:id]
  instance = Instance.find(id)
  instance.put(:shutdown)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/image-list' do
  imagelist = ImageStorage.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[]}
  rtn['totalCount'] = imagelist.length
  imagelist.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
    rows.store('nm','centos5.4-i386-1part-aio-4gb-2009121801')
    rows.store('od','staff')
    rows.store('vy','public')
    rows.store('ac','i386')
    rtn['rows'].push(rows)
  }
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/user-list' do
  userlist = User.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[]}
  rtn['totalCount'] = userlist.length
  userlist.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
    rows.store('nm',index.name)
    rows.store('en',index.enable)
    # rows.store('em',index.email)
    rows.store('mm',index.memo)
    rtn['rows'].push(rows)
  }
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/physicalhost-list' do
  physicalhostlist = PhysicalHost.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[]}
  rtn['totalCount'] = physicalhostlist.length
  physicalhostlist.each{|index|
    rows = Hash::new
    rows.store('id'  ,index.id)
    rows.store('cpus',index.cpus)
    rows.store('mhz' ,index.cpu_mhz)
    rows.store('memory',index.memory)
    rtn['rows'].push(rows)
  }
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/map_upload' do
  name = params[:nm]
  memo = params[:mm]
  rtn = {"success"=>false , "file"=>params[:file][:filename]}
  if params[:file]
    new_filename = DateTime.now.strftime('%s') + File.extname(params[:file][:filename])
    save_file = './public/images/map/' + new_filename
    File.open(save_file, 'wb'){ |f| f.write(params[:file][:tempfile].read) }
    rtn['success'] = true
  end
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/map-list' do
  rtn = {'count'=>0}
  resource = ResourceManeger.new
  rtn = resource.getMaps(ResourceManeger::M_ONLY)
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/rack-list' do
  id = params[:id]
  rtn = {'success'=>false}
  resource = ResourceManeger.new
  rtn.store(:racks,resource.getRacks(id,ResourceManeger::R_SV,true))
  rtn['success'] = true
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/user-create' do
  name = params[:user_name]
  email = params[:email]
  password = params[:password]
  enable = params[:enable] == 'on' ? 1:0
  memo = params[:memo]
  User.create(:name=>name,
              :email=>email,
              :password=>password,
              :enable=>enable,
              :memo=>memo
              )
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/user-edit' do
  name = params[:user_name]
  email = params[:email]
  password = params[:password]
  enable = params[:enable] == 'on' ? 1:0
  memo = params[:memo]
  begin
    debug_log params
    user = User.find(params[:user_id])
    user.name = name
    # user.email = email #todo update email
    user.password = 'passwd' #todo not required
    user.enable = enable
    user.memo = memo
    user.save
    rtn = {"success" => true}
  end
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/user-remove' do
  id = params[:id]
  rtn = {"success" => false}
  begin
    account = User.find(id)
    account.destroy
    rtn = {"success" => true}
  end
  debug_log rtn
  content_type :json
  rtn.to_json
end
