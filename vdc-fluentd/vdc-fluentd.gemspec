# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "vdc-fluentd"
  spec.version       = "0.0.1"
  spec.authors       = [%q{axsh Ltd.}]
  spec.email         = ['dev@axsh.net']
  spec.summary       = %q{fluentd for Wakame-vdc}
  spec.licenses      = ['LGPL 3.0']
  spec.homepage      = %q{http://wakame.jp/}
  spec.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  spec.files         = `git ls-files`.split($\)
  spec.require_paths = ["lib"]
  spec.has_rdoc = false
  spec.add_runtime_dependency 'fluentd', '0.10.33'
  spec.add_runtime_dependency 'cassandra'
  spec.add_runtime_dependency 'metric_libs'
  spec.add_runtime_dependency 'dolphin_client'
end
