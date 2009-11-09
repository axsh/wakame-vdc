require 'rubygems'
require 'sequel'

DB = Sequel.connect('mysql://localhost/wakame_dcmgr?user=wakame_dcmgr&password=<passwd>')

# models
