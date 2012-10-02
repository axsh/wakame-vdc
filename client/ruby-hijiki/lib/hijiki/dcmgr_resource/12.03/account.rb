# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Account < Base
    initialize_user_result nil, [:id,
                                 :created_at,
                                 :updated_at,
                                ]

    def usage
      self.get(:usage, {:service_type => 'std'})
    end
  end
end
