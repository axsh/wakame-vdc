# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class DcNetwork < Base
    include Hijiki::DcmgrResource::Common::ListMethods

    initialize_user_result nil, [:id,
                                 :created_at,
                                 :updated_at,
                                ]
  end
end
