@admin_config = YAML::load(ERB.new(IO.read(File.join(Dir.getwd, 'config', 'database.yml'))).result)[Padrino.env.to_s]

Sequel::Model.plugin(:schema)
Sequel::Model.raise_on_save_failure = false # Do not throw exceptions on failure
Sequel::Model.db = Sequel.connect("#{@admin_config['adapter']}://#{@admin_config['user']}:#{@admin_config['password']}@#{@admin_config['host']}/#{@admin_config['database']}", :loggers => [logger])
Sequel::MySQL.default_charset = 'utf8'
Sequel::MySQL.default_collate = 'utf8_general_ci'
Sequel::MySQL.default_engine = 'InnoDB'
Sequel.default_timezone = :utc
