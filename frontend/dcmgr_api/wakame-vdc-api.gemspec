# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "wakame-vdc-api"
  s.version = "11.12.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["axsh Ltd."]
  s.date = "2012-07-30"
  s.description = "Datacenter Hypervisor API Frontend"
  s.email = ["dev@axsh.net"]
  s.files = []
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubygems_version = "1.8.10"
  s.summary = "Wakame-VDC: API frontend"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mysql>, ["= 2.8.1"])
      s.add_runtime_dependency(%q<sequel>, ["= 3.27.0"])
      s.add_runtime_dependency(%q<sinatra>, ["= 1.2.6"])
      s.add_runtime_dependency(%q<json>, ["= 1.6.3"])
    else
      s.add_dependency(%q<mysql>, ["= 2.8.1"])
      s.add_dependency(%q<sequel>, ["= 3.27.0"])
      s.add_dependency(%q<sinatra>, ["= 1.2.6"])
      s.add_dependency(%q<json>, ["= 1.6.3"])
    end
  else
    s.add_dependency(%q<mysql>, ["= 2.8.1"])
    s.add_dependency(%q<sequel>, ["= 3.27.0"])
    s.add_dependency(%q<sinatra>, ["= 1.2.6"])
    s.add_dependency(%q<json>, ["= 1.6.3"])
  end
end
