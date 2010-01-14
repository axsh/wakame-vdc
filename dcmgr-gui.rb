require 'rubygems'  
require 'sinatra'
require 'erb'
require 'WakameWebAPI'
require 'logger'

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
  rtn = {
    'totalCount'=>0,
    'rows'=>[]
  }
  rtn['totalCount'] = instanceList.length
  instanceList.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
#  rows.store('nm',index.name)
#  rows.store('rg',index.created_at)
#  rows.store('cn',index.contract_at)
#  rows.store('en',index.enable)
   rtn['rows'].push(rows)
  }
  content_type :json
  rtn.to_json
end

get '/image-list' do
  imagelist = ImageStorage.find(:all)
  rtn = {
    'totalCount'=>0,
    'rows'=>[]
  }
  rtn['totalCount'] = imagelist.length
  imagelist.each{|index|
    rows = Hash::new
    rows.store('id',index.id)
    rtn['rows'].push(rows)
  }
  content_type :json
  rtn.to_json
end

