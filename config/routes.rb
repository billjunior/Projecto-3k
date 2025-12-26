Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  # Password Change (First Login)
  get 'change_password', to: 'password_changes#show'
  put 'change_password', to: 'password_changes#update'

  # Cyber Café - Daily Revenues
  resources :daily_revenues
  resources :training_courses

  # Company Settings (Singleton resource)
  resource :company_settings, only: [:edit, :update]

  # Service Catalog
  resources :services do
    member do
      post :toggle_active
    end
  end

  # User Management (Directors only)
  resources :users, except: [:show] do
    member do
      post :reset_password
      post :lock_account
      post :unlock_account
    end
  end

  # Root
  root 'dashboard#index'

  # Dashboard
  get 'dashboard', to: 'dashboard#index', as: :dashboard

  # Main resources
  resources :customers do
    resources :contacts do
      member do
        post :set_as_primary
      end
    end
    resources :communications
  end

  resources :products do
    resources :price_rules, only: [:create, :update, :destroy]
  end

  resources :estimates do
    collection do
      post :validate_pricing
    end
    member do
      post :submit_for_approval
      post :approve
      post :reject
      post :convert_to_job
      get :pdf
    end
    resources :estimate_items, only: [:create, :update, :destroy]
  end

  resources :jobs do
    member do
      patch :update_status
    end
    resources :job_items, only: [:create, :update, :destroy]
    resources :job_files, only: [:create, :destroy]
  end

  resources :lan_machines
  resources :lan_sessions do
    member do
      post :close
    end
  end

  # Inventory management
  resources :inventory_items do
    collection do
      get :reports
    end
    resources :inventory_movements, only: [:create, :destroy]
  end

  # Missing Items
  resources :missing_items do
    member do
      patch :mark_as_ordered
      patch :mark_as_resolved
    end
  end

  resources :invoices do
    collection do
      get :pricing_calculator
      post :calculate_price
      post :validate_pricing
    end
    member do
      get :pdf
    end
    resources :payments, only: [:create, :destroy]
  end

  resources :tasks

  # Reports (Admin only)
  resources :reports, only: [:index] do
    collection do
      get :lan_sessions
      get :invoices
      get :customers
      get :opportunities
      get :sales
      get :inventory
      get :daily_revenues
      get :training_courses
      get :contact_sources
      get :pricing_analysis
    end
  end

  # Audit Logs (Admin only)
  resources :audit_logs, only: [:index, :show]

  # CRM - Leads and Opportunities
  resources :leads do
    member do
      post :convert_to_customer
    end
    resources :contacts do
      member do
        post :set_as_primary
      end
    end
    resources :communications
  end

  resources :opportunities do
    collection do
      get :kanban
    end
    member do
      post :mark_as_won
      post :mark_as_lost
      post :convert_to_estimate
      patch :update_stage
    end
    resources :communications
  end

  # Admin namespace (Super Admin only)
  namespace :admin do
    resources :tenants do
      member do
        post :extend_subscription
      end
    end

    resources :subscriptions, only: [:index] do
      member do
        post :renew
        post :suspend
        post :activate
        post :grant_trial
      end
    end
  end

  # Subscription management
  resource :subscription, only: [] do
    get :expired
    post :renew_request
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
