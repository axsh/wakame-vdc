require 'rubygems'  
require 'logger'
require 'sinatra'
require 'erb'
require 'WakameWebAPI'
require 'parsedate'
require 'date'
require 'resource_maneger'
require 'dcmgr-gui-auth'
require 'define'

if DEBUG_LOG
  @@logger = Logger.new('dcmgr-gui.log')
  def @@logger.write(str)
    self << str
  end
  use Rack::CommonLogger, @@logger
end

def debug_log(str)
  @@logger.debug str if DEBUG_LOG
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
  need_auth 'center' do
    erb :center
  end
end
get '/center/login' do
  login('center')
end
post '/center/login' do
  login('center')
end
get '/client/' do
  need_auth 'client' do
    erb :client
  end
end
get '/client/login' do
  login('client')
end
post '/client/login' do
  login('client')
end
get '/center/logout' do
  logout('/center/login')
end
get '/client/logout' do
  logout('/center/login')
end
#################################

post '/account-create' do
  name = params[:nm]
  cdate = params[:cn]
  enable = params[:en]
  memo = params[:mm]
  Account.login(session[:login_id],session[:login_pw])
  Account.create(:name=>name,
                 :enable=>enable,
                 :memo=>memo,
                 :contract_at=>cdate)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/account-save' do
  id = params[:id]
  Account.login(session[:login_id],session[:login_pw])
  account = Account.find(id)
  account.name = params[:nm]
  account.enable = params[:en]
  account.memo = params[:mm]
  ary = ParseDate::parsedate(params[:cn])
  account.contract_at = Time::local(*ary[0..-3])
  account.save
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/account-search' do 
  id = params[:id]
  nm = params[:nm]
  en = params[:en]
  cn = params[:cn]

  Account.login(session[:login_id],session[:login_pw])
  accountList = nil
  rtn = {'success'=>false,'totalCount'=>0,'rows'=>[]}

  fromDate = nil;
  toDate = nil;
  if cn.length > 0
    ary = ParseDate::parsedate(cn)
    fromDate = Time::local(*ary[0..-3])
    toDate = fromDate + 3600*24
  end

  if id.length > 0
    accountList = Account.find(:all, :params=>{:id=>id})
  elsif cn.length > 0
    if en != "0"
      if en == "1"
        if nm.length > 0
          accountList = Account.find(:all, :params=>{:name=>nm,:enable=>true,:contract_at=>[fromDate,toDate]})
        else
          accountList = Account.find(:all, :params=>{:enable=>true,:contract_at=>[fromDate,toDate]})
        end
      else
        if nm.length > 0
          accountList = Account.find(:all, :params=>{:name=>nm,:enable=>false,:contract_at=>[fromDate,toDate]})
        else
          accountList = Account.find(:all, :params=>{:enable=>false,:contract_at=>[fromDate,toDate]})
        end
      end
    else
      if nm.length > 0
        accountList = Account.find(:all, :params=>{:name=>nm,:contract_at=>[fromDate,toDate]})
      else
        accountList = Account.find(:all, :params=>{:contract_at=>[fromDate,toDate]})
      end
    end
  elsif en != "0"
    if nm.length > 0
      if en == "1"
        accountList = Account.find(:all, :params=>{:enable=>true,:name=>nm})
      else
        accountList = Account.find(:all, :params=>{:enable=>false,:name=>nm})
      end
    else
      if en == "1"
        accountList = Account.find(:all, :params=>{:enable=>true})
      else
        accountList = Account.find(:all, :params=>{:enable=>false})
      end
    end
  elsif nm.length > 0
    accountList = Account.find(:all, :params=>{:name=>nm})
  else
    accountList = Account.find(:all)
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
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/account-remove' do
  id = params[:id]
  Account.login(session[:login_id],session[:login_pw])
  account = Account.find(id)
  account.destroy
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/account-list' do
  Account.login(session[:login_id],session[:login_pw])
  accountList = Account.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[]}
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
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/instance-list' do
  Instance.login(session[:login_id],session[:login_pw])
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
  Instance.login(session[:login_id],session[:login_pw])
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
  Instance.login(session[:login_id],session[:login_pw])
  id = params[:id]
  wd = params[:wd]
  tp = params[:tp]
  cups=@@instanceType[tp][0]
  cpu_mhz=@@instanceType[tp][1]
  memory=@@instanceType[tp][2]
  instance = Instance.create(
               :account=>id,
               :wid=>wd,
               :need_cpus=>cups,
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
  Instance.login(session[:login_id],session[:login_pw])
  instance = Instance.find(id)
  instance.put(:reboot)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-save' do
  id = params[:id]
  Instance.login(session[:login_id],session[:login_pw])
  instance = Instance.find(id)
  instance.put(:save)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-terminate' do
  id = params[:id]
  Instance.login(session[:login_id],session[:login_pw])
  instance = Instance.find(id)
  instance.put(:shutdown)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/image-list' do
  ImageStorage.login(session[:login_id],session[:login_pw])
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
  User.login(session[:login_id],session[:login_pw])
  userlist = User.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[]}
  rtn['totalCount'] = userlist.length
  userlist.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
    rows.store('nm',index.name)
    rows.store('st','')
    rows.store('en',index.enable)
    rows.store('em',index.email)
    rows.store('mm',index.memo)
    rtn['rows'].push(rows)
  }
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/physicalhost-list' do
  PhysicalHost.login(session[:login_id],session[:login_pw])
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
  rtn.store(:racks,resource.getRacks(id,ResourceManeger::R_SV))
  rtn['success'] = true
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/user-create' do
  debug_log params
  name = params[:user_name]
  email = params[:email]
  password = params[:password]
  enable = params[:enable] == 'on' ? 1:0
  memo = params[:memo]
  User.login(session[:login_id],session[:login_pw])
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
