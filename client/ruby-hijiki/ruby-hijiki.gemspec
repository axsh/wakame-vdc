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
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Wakame-VDC: API library}

  s.files = [%q{Gemfile}, %q{Rakefile}, %q{lib/hijiki.rb}, %q{lib/hijiki/dcmgr_resource/11.12/account.rb}, %q{lib/hijiki/dcmgr_resource/11.12/base.rb}, %q{lib/hijiki/dcmgr_resource/11.12/host_node.rb}, %q{lib/hijiki/dcmgr_resource/11.12/image.rb}, %q{lib/hijiki/dcmgr_resource/11.12/instance.rb}, %q{lib/hijiki/dcmgr_resource/11.12/instance_spec.rb}, %q{lib/hijiki/dcmgr_resource/11.12/network.rb}, %q{lib/hijiki/dcmgr_resource/11.12/security_group.rb}, %q{lib/hijiki/dcmgr_resource/11.12/ssh_key_pair.rb}, %q{lib/hijiki/dcmgr_resource/11.12/storage_node.rb}, %q{lib/hijiki/dcmgr_resource/11.12/volume.rb}, %q{lib/hijiki/dcmgr_resource/11.12/volume_snapshot.rb}, %q{lib/hijiki/dcmgr_resource/12.03/account.rb}, %q{lib/hijiki/dcmgr_resource/12.03/base.rb}, %q{lib/hijiki/dcmgr_resource/12.03/host_node.rb}, %q{lib/hijiki/dcmgr_resource/12.03/image.rb}, %q{lib/hijiki/dcmgr_resource/12.03/instance.rb}, %q{lib/hijiki/dcmgr_resource/12.03/instance_spec.rb}, %q{lib/hijiki/dcmgr_resource/12.03/network.rb}, %q{lib/hijiki/dcmgr_resource/12.03/security_group.rb}, %q{lib/hijiki/dcmgr_resource/12.03/ssh_key_pair.rb}, %q{lib/hijiki/dcmgr_resource/12.03/storage_node.rb}, %q{lib/hijiki/dcmgr_resource/12.03/volume.rb}, %q{lib/hijiki/dcmgr_resource/12.03/volume_snapshot.rb}, %q{lib/hijiki/dcmgr_resource/base.rb}, %q{ruby-hijiki.gemspec}, %q{test/api/ts_base.rb}, %q{test/api/ts_host_node.rb}, %q{test/api/ts_image.rb}, %q{test/api/ts_instance.rb}, %q{test/api/ts_network.rb}, %q{test/api/ts_ssh_key_pair.rb}, %q{test/api/ts_storage_node.rb}, %q{test/api/ts_volume.rb}, %q{test/api/ts_volume_snapshot.rb}, %q{test/ts_all.rb}]

end
