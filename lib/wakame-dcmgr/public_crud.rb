# -*- coding: utf-8 -*-

def public_crud model
  model.public_actions.each{|method_name, pattern, actiontag, args|
    puts "#{method_name} #{pattern}, #{actiontag}, #{args}"
    eval("#{method_name} pattern, &model.get_action(model, actiontag, args)")
  }
end

