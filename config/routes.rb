Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  # Cyber Café - Daily Revenues
  resources :daily_revenues
  resources :training_courses

  # Company Settings (Singleton resource)
  resource :company_settings, only: [:edit, :update]

  # Root
  root 'dashboard#index'

  # Dashboard
  get 'dashboard', to: 'dashboard#index', as: :dashboard

  # Main resources
  resources :customers
  resources :products do
    resources :price_rules, only: [:create, :update, :destroy]
  end

  resources :estimates do
    member do
      post :submit_for_approval
      post :approve
      post :reject
      post :convert_to_job
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

  resources :invoices do
    collection do
      get :pricing_calculator
      post :calculate_price
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
    end
  end

  # Audit Logs (Admin only)
  resources :audit_logs, only: [:index, :show]

  # CRM - Leads and Opportunities
  resources :leads do
    member do
      post :convert_to_customer
    end
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
  end

  # Admin namespace (Super Admin only)
  namespace :admin do
    resources :tenants do
      member do
        post :extend_subscription
      end
    end
  end

  # Subscription management
  resource :subscription, only: [] do
    get :expired
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
