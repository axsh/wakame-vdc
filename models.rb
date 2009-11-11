#!/usr/bin/ruby

require 'rubygems'
require 'sequel'

DB = Sequel.connect('mysql://localhost/wakame_dcmgr?user=wakame_dcmgr&password=passwd')

# models
class Groups < Sequel::Model; end

class Users < Sequel::Model; end

class Instances < Sequel::Model; end

class ImageStorages < Sequel::Model; end

class HvSpecs < Sequel::Model; end

class PhysicalHosts < Sequel::Model; end

class HvControllers < Sequel::Model; end

class HvAgents < Sequel::Model; end
