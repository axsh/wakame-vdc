require 'json'

DcmgrAdmin.controllers :data do
  get "/instances", :provides => [:json] do
    data = []

    # request to dcmgr
    
    # 20.times do |i|
    #   data.push({
    #     :display_name => "name%s" % i.to_s
    #   })
    # end
    
    data.to_json
  end
end