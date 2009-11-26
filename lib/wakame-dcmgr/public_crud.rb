# -*- coding: utf-8 -*-

def public_crud model
  pat = %r{/instances/(\d+).json}
  # get pat, &proc { |id| "abc " + id }
  model.public_actions.each{|method_name, pattern, actiontag, args|
    puts "#{method_name} #{pat}, #{pattern}, #{model}, #{actiontag}, #{args})"
    eval("#{method_name} pattern, &model.get_action(model, actiontag, args)")
  }
end

