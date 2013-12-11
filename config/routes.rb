Neurotelcal::Application.routes.draw do
  namespace :operators do
    devise_for :users, controllers: { sessions: 'operators/sessions', passwords: 'devise/passwords'}

    get "monitor/index"
    get "monitor/cdr"
    get "monitor/channels_status"
    get "monitor/campaigns_status"
    get "operator/dashboard"
    resources :clients do
      get 'new_upload_massive', :on => :collection
      post 'create_upload_massive', :on => :collection
    end
    resources :operator
    resources :resources
  end
  
  devise_for :users

  resources :distributors do
    get 'enable'
    get 'disable'
  end

  get "notification/index"

  get "monitor/index"

  get "monitor/campaigns_status"

  get "monitor/channels_status"
  get "monitor/cdr"

  resources :tools do 
    get 'new_import_cdr', :on => :collection
    post 'create_import_cdr', :on => :collection

    get 'restore_archive'
    get 'index_archive', :on => :collection
    get 'new_archive', :on => :collection
    post 'create_archive', :on => :collection
    delete "destroy_archive"
  end


  resources :entities

  resources :message_calendars

  get "page/about"

  get "reports/index"
  get "reports/new_export_csv"
  post "reports/export_csv"
  get "reports/export_csv_index"
  post "reports/export_with_format"
  get "reports/export"
  
  controller :sessions do
    get 'login' => :new
    post 'login' => :create
    delete 'logout' => :destroy
  end

  resources :users


  get 'plivos/report'
  resources :plivos do
    
    member do
      post 'answer_client', :defaults => { :format => 'xml' }, :constraints => WhitelistPlivoConstraint.new
      post 'hangup_client', :defaults => { :format => 'xml' }, :constraints => WhitelistPlivoConstraint.new
      post 'ringing_client', :defaults => { :format => 'xml' }, :constraints => WhitelistPlivoConstraint.new
      post 'get_digits_client', :defaults => { :format => 'xml' }, :constraints => WhitelistPlivoConstraint.new
      post 'continue_sequence_client', :defaults => { :format =>  'xml' }, :constraints => WhitelistPlivoConstraint.new
      post 'contact_client', :defaults => { :format => 'xml' }, :constraints => WhitelistPlivoConstraint.new
    end
    
    #post 'get_digits_client/:id' => 'plivos#get_digits_client', :defaults => { :format => 'xml' }, :on => :collection
    post 'hangup_client', :defaults => { :format => 'xml' }, :on => :collection, :constraints => WhitelistPlivoConstraint.new
    post 'answer_client', :defaults => { :format => 'xml' }, :on => :collection, :constraints => WhitelistPlivoConstraint.new
  end

  resources :groups do
    put 'status_start'
    put 'status_stop'
  end
  

  resources :clients do
    get 'new_upload_massive', :on => :collection
    post 'create_upload_massive', :on => :collection
  end

  resources :messages do

    member do
      get 'call_client'
      post 'docall_client'
    end
  end
  
  resources :resources

  resources :campaigns do
    delete 'destroy_deep'
    put 'change_status'
    put 'status_start'
    put 'status_pause'
    put 'status_end'
    get 'status'
  end
  
  
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
  # root :to => 'welcome#index'
  root :to => 'campaigns#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
