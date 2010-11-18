DcmgrGui::Application.routes.draw do
  root :to => "home#index"

  # match ':controller(/:action(/:id))'
  
  #account
  post   'accounts/switch' ,:to => 'accounts#switch'
  get    'accounts' ,:to => 'acounts#index'
  
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
  
  #home
  get    'home' ,:to => 'home#index'
  
  #host_pools
  get    'host_pools' ,:to => 'host_pools#index'
  get    'host_pools/list/:id' ,:to => 'host_pools#list'
  get    'host_pools/show/:id' ,:to => 'host_pools#show'
  get    'host_pools/show_host_pools' ,:to => 'host_pools#show_host_pools'
  
  #images
  get    'images' ,:to => 'images#index'
  get    'images/total',:to => 'images#total'
  get    'images/list/:id' ,:to => 'images#list'
  get    'images/show/:id' ,:to => 'images#show'
  
  
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
  
  #kepairs
  get    'keypairs' ,:to => 'keypairs#index'
  get    'keypairs/list/:id' ,:to => 'keypairs#list'
  get    'keypairs/create_ssh_keypair' ,:to => 'keypairs#create_ssh_keypair'
  get    'keypairs/all' ,:to => 'keypairs#show_keypairs'
  get    'keypairs/total' ,:to => 'keypairs#total'
  get    'keypairs/prk_download/:id' ,:to => 'keypairs#prk_download'
  get    'keypairs/show/:id' ,:to => 'keypairs#show'
  delete 'keypairs/:id' ,:to => 'keypairs#destroy'
  
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
  
  #sessions
  get    'login' => 'sessions#new', :as => :login
  get    'logout' => 'sessions#destroy', :as => :logout
  resource :session, :only => [:new, :create, :destroy]
  
  #storage_pools
  get    'storage_pools' ,:to => 'storage_pools#index'
  get    'storage_pools/list/:id' ,:to => 'storage_pools#list'
  get    'storage_pools/show/:id' ,:to => 'storage_pools#show'
  get    'storage_pools/show_storage_pools' ,:to => 'storage_pools#show_storage_pools'
  
  #users
  
  #volumes
  get    'volumes' ,:to => 'volumes#index'
  get    'volumes/list/:id' ,:to => 'volumes#list'
  put    'volumes/attach' ,:to => 'volumes#attach'
  put    'volumes/detach' ,:to => 'volumes#detach'
  get    'volumes/total' ,:to => 'volumes#total'
  get    'volumes/show/:id' ,:to => 'volumes#show'
  post   'volumes' ,:to => 'volumes#create'
  delete 'volumes' ,:to => 'volumes#destroy'

end
