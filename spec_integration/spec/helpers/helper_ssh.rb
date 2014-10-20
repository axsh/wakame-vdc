# -*- coding: utf-8 -*-

def ssh_to_instance(&blk)
  Net::SSH.start(
    extract_ip_address(@instance.vif, config[:nw_management_uuid]),
    'root',
    :keys => [@key_files[@instance.id]],
    :user_known_hosts_file => '/dev/null',
    :paranoid => false,
    &blk
  )
end
