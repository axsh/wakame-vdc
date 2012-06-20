# -*- coding: utf-8

require 'hijiki'

Hijiki.load(File.expand_path('config/instance_spec.yml', ::Rails.root))

Hijiki::DcmgrResource.setup_aliases(:V1203)
