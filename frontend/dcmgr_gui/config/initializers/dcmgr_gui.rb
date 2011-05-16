ActiveResource::Connection.class_eval do 
  class << self
    def set_vdc_account_uuid(uuid)
      class_variable_set(:@@vdc_account_uuid,uuid)
    end
  end
end

ActiveResource::Base.class_eval do 
  begin
    @dcmgr_gui_config = YAML::load(IO.read(File.join(Rails.root, 'config', 'dcmgr_gui.yml')))[Rails.env]
  rescue Errno::ENOENT => e
    Rails.logger.error(e.message)
    exit 1
  end
  self.site = @dcmgr_gui_config['dcmgr_site'] 
end

@dcmgr_config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'database.yml'))).result)[Rails.env]
Schema.connect "#{@dcmgr_config['adapter']}://#{@dcmgr_config['host']}/#{@dcmgr_config['database']}?user=#{@dcmgr_config['user']}&password=#{@dcmgr_config['password']}"
