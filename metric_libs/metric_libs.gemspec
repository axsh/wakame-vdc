# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

require File.expand_path('../lib/metric_libs/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "metric_libs"
  spec.version       = MetricLibs::VERSION

  spec.authors       = ['axsh Ltd.']
  spec.email         = ['dev@axsh.net']
  spec.description   = %q{Metric Libs is utility}
  spec.summary       = %q{Metric Library}
  spec.licenses      = ['LGPL 3.0']
  spec.required_ruby_version     = '>= 1.9'
  spec.required_rubygems_version = '>= 1.3.6'

  spec.files         = `git ls-files`.split($\)
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ["lib"]
  spec.has_rdoc = false
end
