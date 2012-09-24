DcmgrGui::Application.routes.draw do
  root :to => "home#index"

  # match ':controller(/:action(/:id))'
  
  #account
  post   'accounts/switch' ,:to => 'accounts#switch'
  get    'accounts' ,:to => 'accounts#index'
  get    'accounts/password' ,:to => 'accounts#password'
  get    'accounts/usage', :to => 'accounts#usage'
  post   'accounts/password' ,:to => 'accounts#password'
  post   'accounts/update_settings', :to => 'accounts#update_settings'

  #dialog
  get    'dialog/create_volume', :to => 'dialog#create_volume'
  post   'dialog/create_volume_from_backup', :to => 'dialog#create_volume_from_backup'
  post   'dialog/attach_volume', :to => 'dialog#attach_volume'
  post   'dialog/detach_volume', :to => 'dialog#detach_volume'
  post   'dialog/delete_volume', :to => 'dialog#delete_volume'
  post   'dialog/edit_volume', :to => 'dialog#edit_volume'
  post   'dialog/create_backup', :to => 'dialog#create_backup'
  post   'dialog/delete_backup', :to => 'dialog#delete_backup'
  post   'dialog/edit_backup', :to => 'dialog#edit_backup'
  get    'dialog/create_network', :to => 'dialog#create_network'
  post   'dialog/edit_network', :to => 'dialog#edit_network'
  post   'dialog/start_instances', :to => 'dialog#start_instances'
  post   'dialog/stop_instances', :to => 'dialog#stop_instances'
  post   'dialog/reboot_instances', :to => 'dialog#reboot_instances'
  post   'dialog/terminate_instances', :to => 'dialog#terminate_instances'
  post   'dialog/edit_instance', :to => 'dialog#edit_instance'
  post   'dialog/backup_instances', :to => 'dialog#backup_instances'
  post   'dialog/poweroff_instances', :to => 'dialog#poweroff_instances'
  post   'dialog/poweron_instances', :to => 'dialog#poweron_instances'
  get    'dialog/create_security_group', :to => 'dialog#create_security_group'
  post   'dialog/delete_security_group', :to => 'dialog#delete_security_group'
  post   'dialog/edit_security_group', :to => 'dialog#edit_security_group'
  post   'dialog/launch_instance', :to => 'dialog#launch_instance'
  post   'dialog/delete_backup_image', :to => 'dialog#delete_backup_image'
  post   'dialog/edit_machine_image', :to => 'dialog#edit_machine_image'
  get    'dialog/create_ssh_keypair', :to => 'dialog#create_ssh_keypair'
  post   'dialog/delete_ssh_keypair', :to => 'dialog#delete_ssh_keypair'
  post   'dialog/edit_ssh_keypair', :to => 'dialog#edit_ssh_keypair'
  get    'dialog/create_load_balancer', :to => 'dialog#create_load_balancer'
  post   'dialog/delete_load_balancer', :to => 'dialog#delete_load_balancer'
  post   'dialog/register_load_balancer', :to => 'dialog#register_load_balancer'
  post   'dialog/unregister_load_balancer', :to => 'dialog#unregister_load_balancer'
  post   'dialog/poweroff_load_balancer', :to => 'dialog#poweroff_load_balancer'
  post   'dialog/poweron_load_balancer', :to => 'dialog#poweron_load_balancer'
  post   'dialog/edit_load_balancer', :to => 'dialog#edit_load_balancer'
  post   'dialog/active_standby_load_balancer', :to => 'dialog#active_standby_load_balancer'

  # user/group managment dialog
  get    'dialog/create_user', :to => 'user_management_dialog#create_user'
  post   'dialog/edit_user', :to => 'user_management_dialog#edit_user'
  post   'dialog/delete_user', :to => 'user_management_dialog#delete_user'
  post   'dialog/link_group', :to => 'user_management_dialog#link_group'
  get    'dialog/create_group', :to => 'user_management_dialog#create_group'
  post   'dialog/edit_group', :to => 'user_management_dialog#edit_group'
  post   'dialog/delete_group', :to => 'user_management_dialog#delete_group'
  post   'dialog/link_user', :to => 'user_management_dialog#link_user'
  post   'dialog/link_group', :to => 'user_management_dialog#link_group'
  
  # vdc-management diaplog
  get    'dialog/create_hn', :to => 'vdc_management_dialog#create_hostnode'
  post   'dialog/create_hn_exec', :to => 'vdc_management_dialog#create_hostnode_exec'
  get    'dialog/edit_and_delete_hn', :to => 'vdc_management_dialog#edit_and_delete_hostnode'
  post   'dialog/get_hn_list', :to => 'vdc_management_dialog#get_hn_list'
  post   'dialog/edit_hn_exec' , :to => 'vdc_management_dialog#edit_hostnode_exec'
  post   'dialog/delete_hn_exec/:id' , :to => 'vdc_management_dialog#delete_hostnode_exec'
  get    'dialog/create_sn', :to => 'vdc_management_dialog#create_storagenode'
  post   'dialog/create_sn_exec', :to => 'vdc_management_dialog#create_storagenode_exec'
  get    'dialog/delete_sn', :to => 'vdc_management_dialog#delete_storagenode'
  post   'dialog/get_sn_list', :to => 'vdc_management_dialog#get_sn_list'
  post   'dialog/delete_sn_exec/:id' , :to => 'vdc_management_dialog#delete_storagenode_exec'
  get    'dialog/create_is', :to => 'vdc_management_dialog#create_spec'
  post   'dialog/create_is_exec', :to => 'vdc_management_dialog#create_spec_exec'
  get    'dialog/edit_and_delete_is', :to => 'vdc_management_dialog#edit_and_delete_spec'
  post   'dialog/get_is_list', :to => 'vdc_management_dialog#get_is_list'
  post   'dialog/edit_is_exec' , :to => 'vdc_management_dialog#edit_spec_exec'
  post   'dialog/delete_is_exec/:id' , :to => 'vdc_management_dialog#delete_spec_exec'
  get    'dialog/additional_drives_and_IFs', :to => 'vdc_management_dialog#additional_drives_and_IFs'
  get    'dialog/get_is_drives_list', :to => 'vdc_management_dialog#get_is_drives_list'
  get    'dialog/get_is_vifs_list', :to => 'vdc_management_dialog#get_is_vifs_list'
  post   'dialog/is_drive_change', :to => 'vdc_management_dialog#is_drive_change'
  post   'dialog/is_vif_change', :to => 'vdc_management_dialog#is_vif_change'
  get    'dialog/create_wmi', :to => 'vdc_management_dialog#create_image'
  post   'dialog/get_md5sum', :to => 'vdc_management_dialog#get_md5sum'
  post   'dialog/create_wmi_exec', :to => 'vdc_management_dialog#create_image_exec'
  get    'dialog/delete_wmi', :to => 'vdc_management_dialog#delete_image'
  post   'dialog/get_wmi_list', :to => 'vdc_management_dialog#get_wmi_list'
  post   'dialog/delete_wmi_exec/:id' , :to => 'vdc_management_dialog#delete_image_exec'

  #home
  get    'home' ,:to => 'home#index'
  
  #host_nodes
  get    'host_nodes' ,:to => 'host_nodes#index'
  get    'host_nodes/list/:id' ,:to => 'host_nodes#list'
  get    'host_nodes/show/:id' ,:to => 'host_nodes#show'
  get    'host_nodes/show_host_nodes' ,:to => 'host_nodes#show_host_nodes'
  
  #machine_images
  get    'machine_images' ,:to => 'machine_images#index'
  get    'machine_images/total',:to => 'machine_images#total'
  get    'machine_images/list/:id' ,:to => 'machine_images#list'
  get    'machine_images/show/:id' ,:to => 'machine_images#show'
  put    'machine_images/:id' ,:to => 'machine_images#update'
  delete 'machine_images/:id' ,:to => 'machine_images#destroy'

  #information
  get    'information' ,:to => 'information#index'
  get    'information/rss' ,:to => 'information#rss'

  #notification
  get    'notification', :to => 'notification#index'

  #instances
  get    'instances' ,:to => 'instances#index'
  get    'instances/total' ,:to => 'instances#total'
  get    'instances/list/:id', :to => 'instances#list'
  post   'instances/terminate' ,:to => 'instances#terminate'
  post   'instances/reboot' ,:to => 'instances#reboot'
  post   'instances' ,:to => 'instances#create'
  get    'instances/show/:id' ,:to => 'instances#show'
  post   'instances/start' ,:to => 'instances#start'
  post   'instances/stop' ,:to => 'instances#stop'
  post   'instances/backup' ,:to => 'instances#backup'
  post   'instances/poweroff' ,:to => 'instances#poweroff'
  post   'instances/poweron' ,:to => 'instances#poweron'
  put    'instances/:id', :to => 'instances#update'
  get    'instances/all', :to => 'instances#show_instances'

  #instance_specs
  get    'instance_specs/all' ,:to => 'instance_specs#show_instance_specs'
  
  #kepairs
  get    'keypairs' ,:to => 'keypairs#index'
  get    'keypairs/list/:id' ,:to => 'keypairs#list'
  get    'keypairs/create_ssh_keypair' ,:to => 'keypairs#create_ssh_keypair'
  put    'keypairs/edit_ssh_keypair/:id' ,:to => 'keypairs#edit_ssh_keypair'
  get    'keypairs/all' ,:to => 'keypairs#show_keypairs'
  get    'keypairs/total' ,:to => 'keypairs#total'
  get    'keypairs/prk_download/:id' ,:to => 'keypairs#prk_download'
  get    'keypairs/show/:id' ,:to => 'keypairs#show'
  delete 'keypairs/:id' ,:to => 'keypairs#destroy'

  #users
  get    'users' ,:to => 'users#index'
  get    'users/list/:id' ,:to => 'users#list'
  post   'users/create_user' ,:to => 'users#create_user'
  post   'users/edit_user/:id' ,:to => 'users#edit_user' 
  get    'users/all' ,:to => 'users#show_users'
  get    'users/total' ,:to => 'users#total'
  get    'users/show/:id' ,:to => 'users#show'
  post   'users/:id' ,:to => 'users#destroy'
  post   'users/link_user_groups/:id' ,:to => 'users#link_user_groups'

  #groups
  get    'groups' ,:to => 'groups#index'
  get    'groups/list/:id' ,:to => 'groups#list'
  post   'groups/create_group' ,:to => 'groups#create_group'
  post   'groups/edit_group/:id' ,:to => 'groups#edit_group' 
  get    'groups/all' ,:to => 'groups#show_groups'
  get    'groups/total' ,:to => 'groups#total'
  get    'groups/show/:id' ,:to => 'groups#show'
  post   'groups/:id' ,:to => 'groups#destroy'
  post   'groups/link_group_users/:id' ,:to => 'groups#link_group_users'
  
  #networks
  get    'networks' ,:to => 'networks#index'
  post   'networks' ,:to => 'networks#create'
  get    'networks/list/:id' ,:to => 'networks#list'
  get    'networks/all' ,:to => 'networks#show_networks'
  get    'networks/total' ,:to => 'networks#total'
  get    'networks/show/:id' ,:to => 'networks#show'
  put    'networks/attach', :to => 'networks#attach'
  put    'networks/detach', :to => 'networks#detach'
  get    'networks/:id/dhcp_ranges' ,:to => 'networks#show_dhcp_ranges'
  put    'networks/:id/dhcp_ranges/add' ,:to => 'networks#add_dhcp_range'
  put    'networks/:id/dhcp_ranges/remove' ,:to => 'networks#remove_dhcp_range'
  get    'networks/:id/services' ,:to => 'networks#show_services'
  post   'networks/:id/services' ,:to => 'networks#create_service'

  #dc_networks
  get    'dc_networks/allows_new_networks' ,:to => 'dc_networks#allows_new_networks'

  #security_groups
  get    'security_groups' ,:to => 'security_groups#index'
  get    'security_groups/list/:id' ,:to => 'security_groups#list'
  get    'security_groups/all' ,:to => 'security_groups#show_groups'
  get    'security_groups/total' ,:to => 'security_groups#total'
  get    'security_groups/show/:id' ,:to => 'security_groups#show'
  post   'security_groups' ,:to => 'security_groups#create'
  delete 'security_groups/:id' ,:to => 'security_groups#destroy'
  put    'security_groups/:id' ,:to => 'security_groups#update'
  
  #backups
  get    'backups' ,:to => 'backups#index'
  get    'backups/list/:id' ,:to => 'backups#list'
  get    'backups/total' ,:to => 'backups#total'
  get    'backups/show/:id' ,:to => 'backups#show'
  delete 'backups/:id' ,:to => 'backups#destroy'
  put    'backups/:id' ,:to => 'backups#update'

  #sessions
  get    'login' => 'sessions#new', :as => :login
  get    'logout' => 'sessions#destroy', :as => :logout
  get    'sessions/information', :to  => 'sessions#information'
  resource :session, :only => [:new, :create, :destroy]
  
  #storage_nodes
  get    'storage_nodes' ,:to => 'storage_nodes#index'
  get    'storage_nodes/list/:id' ,:to => 'storage_nodes#list'
  get    'storage_nodes/show/:id' ,:to => 'storage_nodes#show'
  get    'storage_nodes/show_storage_nodes' ,:to => 'storage_nodes#show_storage_nodes'
  
  #volumes
  get    'volumes' ,:to => 'volumes#index'
  get    'volumes/list/:id' ,:to => 'volumes#list'
  put    'volumes/attach' ,:to => 'volumes#attach'
  put    'volumes/detach' ,:to => 'volumes#detach'
  put    'volumes/backup' ,:to => 'volumes#backup'
  get    'volumes/total' ,:to => 'volumes#total'
  get    'volumes/show/:id' ,:to => 'volumes#show'
  post   'volumes' ,:to => 'volumes#create'
  delete 'volumes' ,:to => 'volumes#destroy'
  put    'volumes/:id' , :to => 'volumes#update'

  #load balancers
  get    'load_balancers', :to => 'load_balancers#index'
  get    'load_balancers/list/:id' ,:to => 'load_balancers#list'
  get    'load_balancers/show/:id', :to => 'load_balancers#show'
  post   'load_balancers', :to => 'load_balancers#create'
  delete 'load_balancers/:id', :to => 'load_balancers#destroy'
  put    'load_balancers/register_instances', :to => 'load_balancers#register_instances'
  put    'load_balancers/unregister_instances', :to => 'load_balancers#unregister_instances'
  put    'load_balancers/poweron/:id', :to => 'load_balancers#poweron'
  put    'load_balancers/poweroff/:id', :to => 'load_balancers#poweroff'
  put    'load_balancers/:id', :to => 'load_balancers#update'

  #resorce (management)
  get    'resource' ,:to => 'resource#index'

  #api
  get    'api/users', :to => 'user_api#index'
  get    'api/users/:id', :to => 'user_api#show'
  get    'api/accounts', :to => 'account_api#index'
  get    'api/accounts/:id', :to => 'account_api#show'
end
