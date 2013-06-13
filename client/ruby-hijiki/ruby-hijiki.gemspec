# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby-hijiki}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{axsh Ltd.}]
  s.date = %q{2012-06-01}
  s.description = %q{Datacenter Hypervisor API Library}
  s.email = [%q{dev@axsh.net}]

  s.homepage = %q{http://wakame.jp/}
  s.require_paths = [%q{lib}]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = %q{1.8.23}
  s.summary = %q{Wakame-VDC: API library}

  s.files = [%q{Gemfile}, %q{Rakefile}] + Dir['lib/**/*.rb']
  
  s.add_dependency 'activeresource', '~> 3.0.0'
  s.add_dependency 'json'
end
