# -*- coding: utf-8 -*-

require 'sequel'
require 'yaml'

if defined? Rails
  config = YAML::load(IO.read(File.expand_path("config/database.yml", Rails.root)))[Rails.env]
else
  # For CLI.
  config = YAML::load(IO.read(File.expand_path("../../database.yml", __FILE__)))[ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development']
end
database_uri = "#{config['adapter']}://#{config['host']}/#{config['database']}?user=#{config['user']}&password=#{config['password']}"
db = Sequel.connect(database_uri)

# Force to set "READ COMMITTED" isolation level.
# This mode is supported by both InnoDB and MySQL Cluster backends.
db.transaction_isolation_level = :committed

if ENV['DEBUG_SQL']
  require 'logger'
  db.loggers << Logger.new(STDERR)
end
case db.adapter_scheme
when :mysql, :mysql2
  Sequel::MySQL.default_charset = 'utf8'
  Sequel::MySQL.default_collate = 'utf8_general_ci'
  Sequel::MySQL.default_engine = ENV['MYSQL_DB_ENGINE'] || 'InnoDB'
end
# Set timezone to UTC
Sequel.default_timezone = :utc
