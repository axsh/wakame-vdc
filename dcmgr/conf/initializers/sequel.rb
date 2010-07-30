# -*- coding: utf-8 -*-

require 'sequel'
db = Sequel.connect(Dcmgr.conf.database_url)

#require 'logger' 
#db.loggers << Logger.new(STDOUT)
