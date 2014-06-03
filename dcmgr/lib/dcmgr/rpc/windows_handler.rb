# -*- coding: utf-8 -*-

module Dcmgr::Rpc
  class WindowsHandler < EndpointBuilder

    include HvaHandler::Helpers

    concurrency 2
    job_thread_pool Isono::ThreadPool.new(2, "WindowsHandle")

    job :launch_windows, proc {
      @hva_ctx = HvaContext.new(self)
      @inst = request.args[0]
      @inst_id = @inst[:uuid]

      encrypted_password = task_session.invoke(
        @hva_ctx.hypervisor_driver_class,
        :get_windows_password_hash,
        [@hva_ctx]
      )

      rpc.request(
        'hva-collector',
        'update_instance',
        @inst_id,
        {encrypted_password: encrypted_password}
      )

      update_instance_state({:state=>:running}, ['hva/instance_started'])
      create_instance_vnics(@inst)
    }, proc { failed_instance_launch_rollback }

  end
end
