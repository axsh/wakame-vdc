# -*- coding: utf-8 -*-

module Dcmgr::Rpc
  class WindowsHandler < EndpointBuilder
    job :get_password_hash, proc {
      hva_ctx = HvaContext.new(self)

      encrypted_password = task_session.invoke(
        hva_ctx.hypervisor_driver_class,
        :get_windows_password_hash,
        [hva_ctx]
      )

      rpc.request(
        'hva-collector',
        'update_instance',
        @inst_id,
        {encrypted_password: encrypted_password}
      )
    }
  end
end
