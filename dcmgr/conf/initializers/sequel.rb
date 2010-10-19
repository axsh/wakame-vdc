# -*- coding: utf-8 -*-

require 'sequel'
db = Sequel.connect(Dcmgr.conf.database_url)
if db.is_a?(Sequel::MySQL::Database)
  Sequel::MySQL.default_charset = 'utf8'
  Sequel::MySQL.default_collate = 'utf8_general_ci'
  Sequel::MySQL.default_engine = 'InnoDB'
end
#require 'logger' 
#db.loggers << Logger.new(STDOUT)
