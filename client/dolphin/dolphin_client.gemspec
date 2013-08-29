# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dolphin_client}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{axsh Ltd.}]
  s.date = %q{2013-08-06}
  s.description = %q{Dolphin Client Library}
  s.email = [%q{dev@axsh.net}]

  s.homepage = %q{http://wakame.jp/}
  s.require_paths = [%q{lib}]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0")
  s.rubygems_version = %q{1.8.23}
  s.summary = %q{Dolphin: client library}

  s.files = [%q{Gemfile}] + Dir['lib/**/*.rb']

  s.add_dependency 'weary', '1.1.3'
  s.add_dependency 'json'
end
