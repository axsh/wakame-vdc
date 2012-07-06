# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Network < Base
    include Hijiki::DcmgrResource::Common::ListMethods

    def find_vif(vif_id)
      NetworkVif.find(vif_id, :params => { :network_id => self.id })
    end

  end
end
