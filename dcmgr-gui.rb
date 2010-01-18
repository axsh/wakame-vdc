require 'rubygems'  
require 'sinatra'
require 'erb'
require 'WakameWebAPI'

##################
get '/' do
 erb :index
end
##################

post '/account-create' do
  name = params[:nm]
  cdate = params[:cn]
  enable = params[:en]
  memo = params[:mm]
  Account.login('staff', 'passwd')
  Account.create(:name=>name)
  rtn = {"success" => true}
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
    rtn['rows'].push(rows)
  }
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
    rows.store('od','')
    rows.store('wd','')
    rows.store('st',index.status)
    rows.store('pub-dns','')
    rows.store('pri-dns','')
    rows.store('ip',index.ip)
    rows.store('tp','')
    rows.store('sv','')
    rtn['rows'].push(rows)
  }
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
  content_type :json
  rtn.to_json
end

post '/instance-reboot' do
  id = params[:id]
  Instance.login('staff', 'passwd')
  instance = Instance.find(id)
  instance.put(:reboot)
  rtn = {"success" => true}
  content_type :json
  rtn.to_json
end

post '/instance-save' do
  id = params[:id]
  Instance.login('staff', 'passwd')
  instance = Instance.find(id)
  instance.put(:save)
  rtn = {"success" => true}
  content_type :json
  rtn.to_json
end

post '/instance-terminate' do
  id = params[:id]
  Instance.login('staff', 'passwd')
  instance = Instance.find(id)
  instance.put(:terminate)
  rtn = {"success" => true}
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
    rows.store('is','')
    rows.store('dc','')
    rtn['rows'].push(rows)
  }
  content_type :json
  rtn.to_json
end
