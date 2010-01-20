require 'rubygems'  
require 'sinatra'
require 'erb'
require 'WakameWebAPI'
require 'logger'

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

post '/account-create' do
  name = params[:nm]
  cdate = params[:cn]
  enable = params[:en]
  memo = params[:mm]
  Account.login('staff', 'passwd')
  Account.create(:name=>name,
                 :enable=>enable,
                 :memo=>memo,
                 :contract_at=>cdate)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/account-list' do
  Account.login('staff', 'passwd')
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
  Instance.login('staff', 'passwd')
  instanceList = Instance.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[] }
  rtn['totalCount'] = instanceList.length
  instanceList.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
    rows.store('od',index.user)
    rows.store('wd',index.image_storage)
    rows.store('st',index.status)
    rows.store('ip',index.ip)
    rows.store('tp','')
    rtn['rows'].push(rows)
  }
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-create' do
  Instance.login('staff', 'passwd')
  id = params[:id]
  wd = params[:wd]
  tp = params[:tp]
  cups=1
  cpu_mhz=0.5
  memory=1
  instance = Instance.create(
                   :account=>id,
                   :wid=>wd,
                   :need_cpus=>cups,
                   :need_cpu_mhz=>cpu_mhz,
                   :need_memory=>memory,
				   :image_storage=>wd)
  instance.put(:run)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-reboot' do
  id = params[:id]
  Instance.login('staff', 'passwd')
  instance = Instance.find(id)
  instance.put(:reboot)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-save' do
  id = params[:id]
  Instance.login('staff', 'passwd')
  instance = Instance.find(id)
  instance.put(:save)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

post '/instance-terminate' do
  id = params[:id]
  Instance.login('staff', 'passwd')
  instance = Instance.find(id)
  instance.put(:terminate)
  rtn = {"success" => true}
  debug_log rtn
  content_type :json
  rtn.to_json
end

get '/image-list' do
  ImageStorage.login('staff', 'passwd')
  imagelist = ImageStorage.find(:all)
  rtn = {'totalCount'=>0,'rows'=>[]}
  rtn['totalCount'] = imagelist.length
  imagelist.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
    rows.store('nm','')
    rows.store('od','')
    rows.store('vy','')
    rows.store('ac','')
    rtn['rows'].push(rows)
  }
  debug_log rtn
  content_type :json
  rtn.to_json
end


get '/user-list' do
  rtn = {'totalCount'=>0,'rows'=>[]}
  rtn['totalCount'] = 2

  rows = Hash::new
  rows.store('id',839438494990)
  rows.store('nm',"sato")
  rows.store('st',"login")
  rows.store('en',"y")
  rows.store('em','xxx@xxx.jp')
  rows.store('mm','xxxxxxxxxx')
  rtn['rows'].push(rows)

  rows = Hash::new
  rows.store('id',238230208490)
  rows.store('nm',"kato")
  rows.store('st',"logout")
  rows.store('en',"y")
  rows.store('em','zzz@xxx.jp')
  rows.store('mm','bbbbbbbbb')
  rtn['rows'].push(rows)

  debug_log rtn
  content_type :json
  rtn.to_json
end
