Rails.application.routes.draw do
  root "pages#login"
  
  get "/login1.html", to: "pages#login"
  get "/dashboard1.html", to: "pages#dashboard"
  get "/profile1.html", to: "pages#profile"
  get "/sample request2.html", to: "pages#sample_request"
  get "/sample requests1.html", to: "pages#sample_requests"
  get "/sample request sheet2.html", to: "pages#sample_request_sheet"
  get "/client-article-dropdown.js", to: "pages#client_article_dropdown"
  get "/accept-invitation.html", to: "pages#accept_invitation"
  
  get "/tracker.html", to: "pages#tracker"
  
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

  post "/api/auth/login", to: "auth#login"
  get "/api/auth/me", to: "auth#me"
  post "/api/auth/accept-invitation", to: "auth#accept_invitation"
  put "/api/auth/reset-password", to: "auth#reset_password"

  get "/api/clients/my-clients", to: "client#my_clients"
  get "/api/clients/test-mapped-clients", to: "client#test_mapped_clients"
  get "/api/clients/my-articles", to: "client#my_articles"

  get "/api/dropdown-options", to: "dropdown_options#index"

  
  post "/api/sample-requests", to: "sample_requests#create"
  get "/api/sample-requests", to: "sample_requests#index"
  get "/api/sample-requests/:requestId", to: "sample_requests#show"
  put "/api/sample-requests/:requestId", to: "sample_requests#update"
  delete "/api/sample-requests/:requestId", to: "sample_requests#destroy"

  get "/api/tracker", to: "tracker#index"
  put "/api/tracker/:requestId/stage", to: "tracker#update_stage"

  get "/internal/db-diagnostic", to: "db_diagnostic#show"
end
