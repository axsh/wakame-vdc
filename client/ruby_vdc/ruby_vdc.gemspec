# -*- encoding: utf-8 -*-
#require File.expand_path('../lib/ruby_vdc/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'ruby-vdc'
#  s.version = RubyVdc::VERSION
  s.version = "0.0.1"
  s.homepage = 'http://'
  s.rubyforge_project = 'ruby-vdc'

  s.authors = [""]
  s.email   = [""]

#  s.files = `git ls-files`.split("\n")
  s.files = `find . -name '*.rb'`.split("\n")

#  s.add_development_dependency 'rake-compiler', '0.7.9'

  s.summary = 'Ruby-Vdc library'
  s.description = ""
end
