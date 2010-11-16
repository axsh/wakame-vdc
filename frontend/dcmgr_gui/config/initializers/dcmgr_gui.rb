DcmgrResource::Config = {
  :site => "http://api.dcmgr.local/",
  :timeout => 30,
  :format => :json,
  :prefix => '/api/',
}

@dcmgr_config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'database.yml'))).result)[Rails.env]
Schema.connect "#{@dcmgr_config['adapter']}://#{@dcmgr_config['host']}/#{@dcmgr_config['database']}?user=#{@dcmgr_config['user']}&password=#{@dcmgr_config['password']}"