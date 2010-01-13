require 'rubygems'  
require 'sinatra'
require 'erb'
require 'WakameWebAPI'
require 'logger'

##################
get '/' do
 erb :index
end

get '/test' do
  rtn = {'rows' => [
   { 'id'=>'AAAAAAA', 'price'=>2000},
   { 'id'=>'BBBBBBB', 'price'=>3000},
   { 'id'=>'CCCCCCC', 'price'=>500},
   { 'id'=>'DDDDDDD', 'price'=>1200},
   { 'id'=>'EEEEEEE', 'price'=>300},
   { 'id'=>'FFFFFFF', 'price'=>220}
  ]}
  content_type :json
  rtn.to_json
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

#----------------------------
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

