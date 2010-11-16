# -*- coding: utf-8 -*-
class Information < BaseNew
  with_timestamps
  inheritable_schema do
    String :title, :size=>255
    String :description, :text=>true
  end
  
end
