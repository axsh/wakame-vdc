require 'rubygems'  
require 'sinatra'
require 'erb'
require 'WakameWebAPI'
require 'logger'
require 'parsedate'
require 'date'
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

post '/account-save' do
  id = params[:id]
  Account.login('staff', 'passwd')
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

  Account.login('staff', 'passwd')

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
  Account.login('staff', 'passwd')
  account = Account.find(id)
  account.destroy
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
  Instance.login('staff', 'passwd')
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
  Instance.login('staff', 'passwd')
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
  instance.put(:shutdown)
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
  User.login('staff', 'passwd')
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
  PhysicalHost.login('staff', 'passwd')
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
