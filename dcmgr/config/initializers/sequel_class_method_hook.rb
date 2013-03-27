# encoding: utf-8

Dcmgr::Models::BaseNew.plugin :hook_class_methods

Dir.glob(File.join(Dcmgr::DCMGR_ROOT, "lib/dcmgr/models/hooks/*_hook.rb")).each do |hook|
  require "dcmgr/models/hooks/#{File.basename(hook).sub(/\.rb/, "")}"
end
