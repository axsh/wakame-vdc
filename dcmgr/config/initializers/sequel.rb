# -*- coding: utf-8 -*-

require 'sequel'
if Sequel::DATABASES.first.nil?
  db = Sequel.connect(Dcmgr.conf.database_url)
else
  db = Sequel::DATABASES.first
end

#require 'logger' 
#db.loggers << Logger.new(STDERR)
if db.is_a?(Sequel::MySQL::Database)
  Sequel::MySQL.default_charset = 'utf8'
  Sequel::MySQL.default_collate = 'utf8_general_ci'
  Sequel::MySQL.default_engine = 'InnoDB'

  db << "SET AUTOCOMMIT=0"
  Dcmgr::Models::BaseNew.default_row_lock_mode = nil
end

# Disable TEXT to Sequel::SQL::Blob translation.
# see the thread: MySQL text turning into blobs
# http://groups.google.com/group/sequel-talk/browse_thread/thread/d0f4c85abe9b3227/9ceaf291f90111e6
# lib/sequel/adapters/mysql.rb
[249, 250, 251, 252].each { |v|
  Sequel::MySQL::MYSQL_TYPES.delete(v)
}

# Set timezone to UTC
Sequel.default_timezone = :utc
