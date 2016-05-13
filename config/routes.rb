Rails.application.routes.draw do
  devise_for :users

  # Routes for the Approved resource:
  # CREATE

  root :controller => 'inspect', :action => "oneoff"
  get "/steal", :controller => "steal", :action => "steal"
  get "/steal/showneighbor", :controller => "steal", :action => "showneighbor"
  get "/steal/showcensustract", :controller => "steal", :action => "showcensustract"
  get "/test", :controller => "addresses", :action => "test"

  get "/getvalues", :controller => "values", :action => "getvalues"
  get "/getvalues/:street/:citystatezip", :controller => "values", :action => "getvalues"
  get "/getvalues/:path/:street/:citystatezip", :controller => "values", :action => "getvalues"
  post "/postvalues", :controller => "values", :action => "getvalues"  

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
  get '/registration/newuser', controller: 'registration', action: 'create'
  get '/registration/showuser', controller: 'registration', action: 'show'
  get '/registration/destroy/:id', controller: 'registration', action: 'destroy'

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
  get "/addresses/destroy/all", controller: 'addresses', action: 'destroyall'
  get "/addresses/destroy/:id", controller: 'addresses', action: 'destroy'

  #------------------------------

  # Routes for the Outputs resource:
  # CREATE
  get '/outputs/new', controller: 'outputs', action: 'new', as: 'new_outputs'
  post '/outputs', controller: 'outputs', action: 'create', as: 'outputs'
  # DELETE
  get '/outputs/destroy/:id', controller: 'outputs', action: 'destroy'
  get '/outputs/destroy/run/:rangeID', controller: 'outputs', action: 'destroyrun'
  get '/outputs/destroy/:start/:end', controller: 'outputs', action: 'destroyrange'


  # READ
  get '/outputs', controller: 'outputs', action: 'index'
  get '/outputs/run/:rangeID', controller: 'outputs', action: 'datarun'
  get '/outputs/decision/:id', controller: 'outputs', action: 'datadecision'
  get '/outputs/:start/:end', controller: 'outputs', action: 'datarange'
  get '/outputs/:id', controller: 'outputs', action: 'data'



  get '/inspect/oneoff', controller: 'inspect', action: 'oneoff'
  get '/inspect/:id', controller: 'inspect', action: 'inspect'
  get '/inspect/:street/:citystatezip', controller: 'inspect', action: 'inspectaddress'
  get '/inspect/decision/:street/:citystatezip', controller: 'inspect', action: 'decision'

  #------------------------------

  # Routes for the Research resource:
  # READ
  get '/research/rurality_info/:id', controller: 'research', action: 'ruralityData'
  get '/research/mls/newlistings/:date(/:size)', controller: 'research', action: 'mlsNewListings'
  get '/research/mls/daysonmarket/:dayCount(/:size)', controller: 'research', action: 'mlsDaysOnMarket'

  # IN TESTING
  get '/research/mlsbyloc', controller: 'research', action: 'mlsDataByGeo'
  get '/research/getoutput(/:id)(/street/:street)(/csz/:citystatezip)', controller: 'research', action: 'getOutputValues'
  get '/research/getmsa/lat/:lat/lon/:lon', :constraints => {:lat => /\-?\d+(.\d+)?/, :lon => /\-?\d+(.\d+)?/}, controller: 'research', action: 'getMsa'

  get '/research/mls/pdq/activeprops/:dayCount', controller: 'research', action: 'mlsAutoPreQual'

  get "/getvalues/:placeid", :controller => "values", :action => "getvalues"

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
