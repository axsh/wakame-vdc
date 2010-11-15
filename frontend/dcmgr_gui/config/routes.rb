DcmgrGui::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "home#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  
  match ':controller(/:action(/:id(.:format)))'

  match 'instances/total(.:format)' => 'instances#total', :via => :get
  match 'images/total(.:format)' => 'images#total', :via => :get
  match 'volumes/total(.:format)' => 'volumes#total', :via => :get
  match 'snapshots/total(.:format)' => 'snapshots#total', :via => :get
  match 'security_groups/total(.:format)' => 'security_groups#total', :via => :get
  match 'keypairs/total(.:format)' => 'keypairs#total', :via => :get
  
  match 'keypairs/all' => 'keypairs#show_keypairs',:via => :get
  match 'keypairs/create_ssh_keypair',:via => :get
  match 'keypairs/prk_download/:id' => 'keypairs#prk_download',:via => :get
  match 'accounts/switch' => 'accounts#new',:via => :post
  match 'accounts',:to => 'acounts#index'
  # match 'signup' => 'users#new', :as => :signup
  # match 'register' => 'users#create', :as => :register
  match 'login' => 'sessions#new', :as => :login
  match 'logout' => 'sessions#destroy', :as => :logout
  
  resource :session, :only => [:new, :create, :destroy]

  resources :volumes do
    post 'create',:on => :member
  end

  resources :keypairs do
  end

  match 'security_groups/:id' => 'security_groups#update',:via => :put
  match 'security_groups/:id' => 'security_groups#destroy',:via => :delete
  resource :security_groups do
    get 'all',:to => 'security_groups#show_groups'
    post 'create',:on => :member
  end

  
end
