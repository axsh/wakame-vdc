ActiveResource::Base.class_eval do 
  self.site = 'http://your.dcmgr.api.server/'
end

@dcmgr_config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'database.yml'))).result)[Rails.env]
Schema.connect "#{@dcmgr_config['adapter']}://#{@dcmgr_config['host']}/#{@dcmgr_config['database']}?user=#{@dcmgr_config['user']}&password=#{@dcmgr_config['password']}"