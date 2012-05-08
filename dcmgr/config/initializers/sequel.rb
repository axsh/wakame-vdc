# -*- coding: utf-8 -*-

require 'sequel'
if Sequel::DATABASES.first.nil?
  db = Sequel.connect(Dcmgr.conf.database_url, :after_connect=>proc { |conn|
                        case conn.class.to_s
                        when 'Mysql2::Client', 'Mysql'
                          # send AUTOCOMMIT=0 for every new connections.
                          conn.query "SET AUTOCOMMIT=0;"
                          conn.query "COMMIT;"
                        end
                      })
else
  db = Sequel::DATABASES.first
end

#require 'logger' 
#db.loggers << Logger.new(STDERR)
case db.adapter_scheme
when :mysql, :mysql2
  Sequel::MySQL.default_charset = 'utf8'
  Sequel::MySQL.default_collate = 'utf8_general_ci'
  Sequel::MySQL.default_engine = 'InnoDB'

  # this is the mysql adapter specific constants. won't work with mysql2.
  if db.adapter_scheme == :mysql
    # Disable TEXT to Sequel::SQL::Blob translation.
    # see the thread: MySQL text turning into blobs
    # http://groups.google.com/group/sequel-talk/browse_thread/thread/d0f4c85abe9b3227/9ceaf291f90111e6
    # lib/sequel/adapters/mysql.rb
    [249, 250, 251, 252].each { |v|
      Sequel::MySQL::MYSQL_TYPES.delete(v)
    }
  end
end
Dcmgr::Models::BaseNew.default_row_lock_mode = nil

# Set timezone to UTC
Sequel.default_timezone = :utc
