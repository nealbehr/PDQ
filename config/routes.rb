Rails.application.routes.draw do
  # Routes for the Approved resource:
  # CREATE

  get "/getallvalues", :controller => "values", :action => "getvalues"

  get "/getonevalue/:street/:citystate/:access", :controller => "onevalue", :action => "getonevalue"
  
  get '/approveds/new', controller: 'approveds', action: 'new', as: 'new_approved'
  post '/approveds', controller: 'approveds', action: 'create', as: 'approveds'

  # READ
  get '/approveds', controller: 'approveds', action: 'index'
  get '/approveds/:id', controller: 'approveds', action: 'show', as: 'approved'

  # UPDATE
  get '/approveds/:id/edit', controller: 'approveds', action: 'edit', as: 'edit_approved'
  patch '/approveds/:id', controller: 'approveds', action: 'update'

  # DELETE
  delete '/approveds/:id', controller: 'approveds', action: 'destroy'
  #------------------------------

  # Routes for the Density resource:
  # CREATE
  get '/densities/new', controller: 'densities', action: 'new', as: 'new_density'
  post '/densities', controller: 'densities', action: 'create', as: 'densities'

  # READ
  get '/densities', controller: 'densities', action: 'index'
  get '/densities/:id', controller: 'densities', action: 'show', as: 'density'

  # UPDATE
  get '/densities/:id/edit', controller: 'densities', action: 'edit', as: 'edit_density'
  patch '/densities/:id', controller: 'densities', action: 'update'

  # DELETE
  delete '/densities/:id', controller: 'densities', action: 'destroy'
  #------------------------------

  # Routes for the Address resource:
  # CREATE
  get '/addresses/new', controller: 'addresses', action: 'new', as: 'new_address'
  post '/addresses', controller: 'addresses', action: 'create', as: 'addresses'

  # READ
  get '/addresses', controller: 'addresses', action: 'index'
  get '/addresses/:id', controller: 'addresses', action: 'show', as: 'address'

  # UPDATE
  get '/addresses/:id/edit', controller: 'addresses', action: 'edit', as: 'edit_address'
  patch '/addresses/:id', controller: 'addresses', action: 'update'

  # DELETE
  get "/addresses/destroy/:id", controller: 'addresses', action: 'destroy'
  #------------------------------

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
