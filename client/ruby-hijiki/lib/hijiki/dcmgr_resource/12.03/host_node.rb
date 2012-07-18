# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class HostNode < Base
    include Hijiki::DcmgrResource::Common::ListMethods
    initialize_user_result nil, [:uuid,
                                 :created_at,
                                 :updated_at,
                                 :node_id,
                                 :arch,
                                 :hypervisor,
                                 :name,
                                 :offering_cpu_cores,
                                 :offering_memory_size,
                                 :status,
                                ]
  end
end
