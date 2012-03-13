DcmgrGui::Application.routes.draw do
  root :to => "home#index"

  # match ':controller(/:action(/:id))'
  
  #account
  post   'accounts/switch' ,:to => 'accounts#switch'
  get    'accounts' ,:to => 'accounts#index'
  get    'accounts/password' ,:to => 'accounts#password'
  post   'accounts/password' ,:to => 'accounts#password'
  post   'accounts/update_settings', :to => 'accounts#update_settings'

  #dialog
  get    'dialog/create_volume', :to => 'dialog#create_volume'
  post   'dialog/create_volume_from_snapshot', :to => 'dialog#create_volume_from_snapshot'
  post   'dialog/attach_volume', :to => 'dialog#attach_volume'
  post   'dialog/detach_volume', :to => 'dialog#detach_volume'
  post   'dialog/delete_volume', :to => 'dialog#delete_volume'
  post   'dialog/create_snapshot', :to => 'dialog#create_snapshot'
  post   'dialog/delete_snapshot', :to => 'dialog#delete_snapshot'
  post   'dialog/start_instances', :to => 'dialog#start_instances'
  post   'dialog/stop_instances', :to => 'dialog#stop_instances'
  post   'dialog/reboot_instances', :to => 'dialog#reboot_instances'
  post   'dialog/terminate_instances', :to => 'dialog#terminate_instances'
  get    'dialog/create_security_group', :to => 'dialog#create_security_group'
  post   'dialog/delete_security_group', :to => 'dialog#delete_security_group'
  post   'dialog/edit_security_group', :to => 'dialog#edit_security_group'
  post   'dialog/launch_instance', :to => 'dialog#launch_instance'
  get    'dialog/create_ssh_keypair', :to => 'dialog#create_ssh_keypair'
  post   'dialog/delete_ssh_keypair', :to => 'dialog#delete_ssh_keypair'
  get    'dialog/create_user', :to => 'dialog#create_user'
  post   'dialog/edit_user', :to => 'dialog#edit_user'
  post   'dialog/delete_user', :to => 'dialog#delete_user'
  post   'dialog/link_group', :to => 'dialog#link_group'
  get    'dialog/create_group', :to => 'dialog#create_group'
  post   'dialog/edit_group', :to => 'dialog#edit_group'
  post   'dialog/delete_group', :to => 'dialog#delete_group'
  post   'dialog/link_user', :to => 'dialog#link_user'
  post   'dialog/link_group', :to => 'dialog#link_group'
  get    'dialog/create_hn', :to => 'dialog#create_hostnode'
  post   'dialog/create_hn_exec', :to => 'dialog#create_hostnode_exec'
  get    'dialog/edit_and_delete_hn', :to => 'dialog#edit_and_delete_hostnode'
  post   'dialog/get_hn_list', :to => 'dialog#get_hn_list'
  post   'dialog/edit_hn_exec' , :to => 'dialog#edit_hostnode_exec'
  post   'dialog/delete_hn_exec/:id' , :to => 'dialog#delete_hostnode_exec'
  get    'dialog/create_sn', :to => 'dialog#create_storagenode'
  post   'dialog/create_sn_exec', :to => 'dialog#create_storagenode_exec'
  get    'dialog/delete_sn', :to => 'dialog#delete_storagenode'
  post   'dialog/get_sn_list', :to => 'dialog#get_sn_list'
  post   'dialog/delete_sn_exec/:id' , :to => 'dialog#delete_storagenode_exec'
  get    'dialog/create_is', :to => 'dialog#create_spec'
  post   'dialog/create_is_exec', :to => 'dialog#create_spec_exec'
  get    'dialog/edit_and_delete_is', :to => 'dialog#edit_and_delete_spec'
  post   'dialog/get_is_list', :to => 'dialog#get_is_list'
  post   'dialog/edit_is_exec' , :to => 'dialog#edit_spec_exec'
  post   'dialog/delete_is_exec/:id' , :to => 'dialog#delete_spec_exec'
  get    'dialog/additional_drives_and_IFs', :to => 'dialog#additional_drives_and_IFs'
  get    'dialog/get_is_drives_list', :to => 'dialog#get_is_drives_list'
  get    'dialog/get_is_vifs_list', :to => 'dialog#get_is_vifs_list'
  post   'dialog/is_drive_change', :to => 'dialog#is_drive_change'
  post   'dialog/is_vif_change', :to => 'dialog#is_vif_change'
  get    'dialog/create_wmi', :to => 'dialog#create_image'
  post   'dialog/get_md5sum', :to => 'dialog#get_md5sum'
  post   'dialog/create_wmi_exec', :to => 'dialog#create_image_exec'
  get    'dialog/delete_wmi', :to => 'dialog#delete_image'
  post   'dialog/get_wmi_list', :to => 'dialog#get_wmi_list'
  post   'dialog/delete_wmi_exec/:id' , :to => 'dialog#delete_image_exec'

  
  #home
  get    'home' ,:to => 'home#index'
  
  #host_pools
  get    'host_pools' ,:to => 'host_pools#index'
  get    'host_pools/list/:id' ,:to => 'host_pools#list'
  get    'host_pools/show/:id' ,:to => 'host_pools#show'
  get    'host_pools/show_host_pools' ,:to => 'host_pools#show_host_pools'
  
  #machine_images
  get    'machine_images' ,:to => 'machine_images#index'
  get    'machine_images/total',:to => 'machine_images#total'
  get    'machine_images/list/:id' ,:to => 'machine_images#list'
  get    'machine_images/show/:id' ,:to => 'machine_images#show'
  
  
  #information
  get    'information' ,:to => 'information#index'
  get    'information/rss' ,:to => 'information#rss'
  
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
  
  #instance_specs
  get    'instance_specs/all' ,:to => 'instance_specs#show_instance_specs'
  
  #kepairs
  get    'keypairs' ,:to => 'keypairs#index'
  get    'keypairs/list/:id' ,:to => 'keypairs#list'
  get    'keypairs/create_ssh_keypair' ,:to => 'keypairs#create_ssh_keypair'
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
  
  #security_groups
  get    'security_groups' ,:to => 'security_groups#index'
  get    'security_groups/list/:id' ,:to => 'security_groups#list'
  get    'security_groups/all' ,:to => 'security_groups#show_groups'
  get    'security_groups/total' ,:to => 'security_groups#total'
  get    'security_groups/show/:id' ,:to => 'security_groups#show'
  post   'security_groups' ,:to => 'security_groups#create'
  delete 'security_groups/:id' ,:to => 'security_groups#destroy'
  put    'security_groups/:id' ,:to => 'security_groups#update'
  
  #snapshots
  get    'snapshots' ,:to => 'snapshots#index'
  get    'snapshots/list/:id' ,:to => 'snapshots#list'
  get    'snapshots/total' ,:to => 'snapshots#total'
  get    'snapshots/show/:id' ,:to => 'snapshots#show'
  post   'snapshots' ,:to => 'snapshots#create'
  delete 'snapshots/:id' ,:to => 'snapshots#destroy'
  get    'snapshots/upload_destination',:to => 'snapshots#upload_destination'

  #sessions
  get    'login' => 'sessions#new', :as => :login
  get    'logout' => 'sessions#destroy', :as => :logout
  get    'sessions/information', :to  => 'sessions#information'
  resource :session, :only => [:new, :create, :destroy]
  
  #storage_pools
  get    'storage_pools' ,:to => 'storage_pools#index'
  get    'storage_pools/list/:id' ,:to => 'storage_pools#list'
  get    'storage_pools/show/:id' ,:to => 'storage_pools#show'
  get    'storage_pools/show_storage_pools' ,:to => 'storage_pools#show_storage_pools'
  
  #volumes
  get    'volumes' ,:to => 'volumes#index'
  get    'volumes/list/:id' ,:to => 'volumes#list'
  put    'volumes/attach' ,:to => 'volumes#attach'
  put    'volumes/detach' ,:to => 'volumes#detach'
  get    'volumes/total' ,:to => 'volumes#total'
  get    'volumes/show/:id' ,:to => 'volumes#show'
  post   'volumes' ,:to => 'volumes#create'
  delete 'volumes' ,:to => 'volumes#destroy'

  #resorce (management)
  get    'resource' ,:to => 'resource#index'
end
