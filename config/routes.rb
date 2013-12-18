Ambgest3::Application.routes.draw do

  netzke

  scope "ambgest" do
    scope "(:locale)", :locale => /en|it/ do
      resources :patients do
        get 'index'
        # The following will recognize routes such as "/patients/:id/manage"      
        member do
          get 'manage'
        end
      end

      resources :schedules do
        get 'index'
      end

      resources :receipts do
        get 'index'
        collection do
          get 'report_detail'
        end
      end

      resources :appointments do
        get 'index'
        # The following (issue_receipt_appointment) will recognize routes such as "POST /ambgest(/:locale)/appointments/:id/issue_receipt(.:format)"      
        member do
          post 'issue_receipt'
        end
        # The following (issue_receipt_appointments) will recognize routes such as "POST /ambgest(/:locale)/appointments/issue_receipt(.:format)"      
        collection do
          post 'issue_receipt'
          get 'report_detail'
        end
      end


      resources :articles do
        get 'index'
      end

      resources :users do
        get 'index'
      end

      resources :app_parameters do
        get 'index'
      end

      match "(index)",          :controller => 'welcome',   :action => 'index',       :as => :index
      match "about",            :controller => 'welcome',   :action => 'about',       :as => :about
      match "contact_us",       :controller => 'welcome',   :action => 'contact_us',  :as => :contact_us
      match "whos_online",      :controller => 'welcome',   :action => 'whos_online', :as => :whos_online
      match "wip",              :controller => 'welcome',   :action => 'wip',         :as => :wip
      match "edit_current_user",:controller => 'welcome',   :action => 'edit_current_user', :as => :edit_current_user

      match "week_plan",        :controller => 'week_plan', :action => 'index',           :as => :week_plan
      match "income_analysis",  :controller => 'week_plan', :action => 'income_analysis', :as => :income_analysis
      match "analysis_pdf",     :controller => 'week_plan', :action => 'report_detail', :as => :analysis_pdf

      match "login",            :controller => 'login',     :action => 'login',       :as => :login
      match "logout",           :controller => 'login',     :action => 'logout',      :as => :logout

      match "kill_session/:id", :controller => 'users',     :action => 'kill_session',:as => :kill_session
      match "setup",            :controller => 'setup',     :action => 'index',       :as => :setup
    end
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

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
