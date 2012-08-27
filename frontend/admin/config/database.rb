Sequel::Model.plugin(:schema)
Sequel::Model.raise_on_save_failure = false # Do not throw exceptions on failure
Sequel::Model.db = case Padrino.env
  when :development then Sequel.connect("mysql2://root:""@localhost/wakame_admin", :loggers => [logger])
  when :production  then Sequel.connect("mysql2://root:""@localhost/wakame_admin", :loggers => [logger])
  when :test        then Sequel.connect("mysql2://root:""@localhost/wakame_admin", :loggers => [logger])
end
