# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-wakame-vdc"
  spec.version       = "0.0.1"
  spec.authors       = [%q{axsh Ltd.}]
  spec.date          = %q{2013-08-06}
  spec.description   = %q{fluent plugin for wakame-vdc}
  spec.email         = ['dev@axsh.net']
  spec.summary       = %q{plugin for wakame-vdc}
  spec.licenses      = ['LGPL 3.0']
  spec.homepage      = %q{http://wakame.jp/}
  spec.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  spec.rubygems_version = %q{1.8.23}
  spec.files         = `git ls-files`.split($\)
  spec.require_paths = ["lib"]
  spec.has_rdoc = false
  spec.add_runtime_dependency "fluentd"
end
