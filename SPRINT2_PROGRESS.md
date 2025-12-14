# SPRINT 2 - SUBSCRIÇÃO E BRANDING - EM PROGRESSO

## ✅ COMPLETO

### 1. Campo super_admin adicionado
- Migration executada: `AddSuperAdminToUsers`
- Campo: `super_admin:boolean` (default: false)
- Índice criado

## 🔄 EM IMPLEMENTAÇÃO

### 2. Lógica de Subscrição
**Arquivos a criar/modificar:**

1. **ApplicationController** - Adicionar before_action para verificar subscrição
```ruby
before_action :check_subscription_status

def check_subscription_status
  return if devise_controller? # Não verificar em login/logout
  return unless current_user
  return if current_user.super_admin? # Super admins não são bloqueados

  if current_user.tenant && current_user.tenant.expired?
    redirect_to subscription_expired_path
  end
end
```

2. **SubscriptionsController** - Para exibir página de expiração
```ruby
class SubscriptionsController < ApplicationController
  skip_before_action :check_subscription_status

  def expired
    # Exibe página informando que subscrição expirou
  end
end
```

3. **View: app/views/subscriptions/expired.html.erb**
```erb
<div class="container mt-5">
  <div class="row justify-content-center">
    <div class="col-md-6">
      <div class="card border-danger">
        <div class="card-header bg-danger text-white">
          <h4><i class="bi bi-exclamation-triangle"></i> Subscrição Expirada</h4>
        </div>
        <div class="card-body">
          <p>A subscrição da sua empresa expirou em <%= current_user.tenant.subscription_end&.strftime('%d/%m/%Y') %>.</p>
          <p>Por favor, contacte o administrador do sistema para renovar a subscrição.</p>
          <%= link_to 'Sair', destroy_user_session_path, data: { turbo_method: :delete }, class: 'btn btn-secondary' %>
        </div>
      </div>
    </div>
  </div>
</div>
```

### 3. Branding Helpers
**Arquivo: app/helpers/branding_helper.rb**
```ruby
module BrandingHelper
  def tenant_logo_tag(options = {})
    return unless current_user&.tenant

    if current_user.tenant.logo.attached?
      image_tag current_user.tenant.logo, options.merge(alt: current_user.tenant.name)
    else
      content_tag :span, current_user.tenant.name, class: 'navbar-brand'
    end
  end

  def tenant_color(type = :primary)
    return unless current_user&.tenant
    current_user.tenant.settings.dig(type.to_s + '_color') || default_color(type)
  end

  private

  def default_color(type)
    case type
    when :primary then '#007bff'
    when :secondary then '#6c757d'
    else '#000000'
    end
  end
end
```

### 4. Admin Namespace
**Estrutura a criar:**
```
app/controllers/admin/
├── base_controller.rb  # Verifica se é super_admin
└── tenants_controller.rb  # CRUD de tenants

app/views/admin/
└── tenants/
    ├── index.html.erb
    ├── show.html.erb
    ├── new.html.erb
    ├── edit.html.erb
    └── _form.html.erb
```

**Admin::BaseController:**
```ruby
class Admin::BaseController < ApplicationController
  before_action :require_super_admin

  private

  def require_super_admin
    unless current_user&.super_admin?
      redirect_to root_path, alert: 'Acesso negado. Apenas Super Administradores.'
    end
  end
end
```

**Admin::TenantsController:**
```ruby
class Admin::TenantsController < Admin::BaseController
  def index
    @tenants = Tenant.all.order(created_at: :desc)
  end

  def show
    @tenant = Tenant.find(params[:id])
  end

  def new
    @tenant = Tenant.new
  end

  def create
    @tenant = Tenant.new(tenant_params)
    if @tenant.save
      redirect_to admin_tenant_path(@tenant), notice: 'Tenant criado com sucesso.'
    else
      render :new
    end
  end

  def edit
    @tenant = Tenant.find(params[:id])
  end

  def update
    @tenant = Tenant.find(params[:id])
    if @tenant.update(tenant_params)
      redirect_to admin_tenant_path(@tenant), notice: 'Tenant atualizado.'
    else
      render :edit
    end
  end

  def extend_subscription
    @tenant = Tenant.find(params[:id])
    @tenant.update(subscription_end: @tenant.subscription_end + params[:months].to_i.months)
    redirect_to admin_tenant_path(@tenant), notice: 'Subscrição estendida.'
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, :subdomain, :status, :subscription_start, :subscription_end, :logo, settings: {})
  end
end
```

### 5. Rotas Admin
**config/routes.rb** - Adicionar:
```ruby
namespace :admin do
  resources :tenants do
    member do
      post :extend_subscription
    end
  end
end

resource :subscription, only: [] do
  get :expired
end
```

### 6. Layout com Logo
**app/views/layouts/application.html.erb** - Modificar linha 32-33:
```erb
<a class="navbar-brand" href="<%= root_path %>">
  <%= tenant_logo_tag(style: 'max-height: 40px;') %>
</a>
```

## 📋 PRÓXIMOS PASSOS

1. ✅ Criar todos os arquivos listados acima
2. ✅ Atualizar User model com `scope :super_admins`
3. ✅ Testar bloqueio de subscrição expirada
4. ✅ Testar upload de logo
5. ✅ Testar painel admin

## 🎯 RESULTADO ESPERADO

Quando Sprint 2 estiver completo:
- Tenants com subscrição expirada não conseguem acessar o sistema
- Super admins podem gerir todos os tenants
- Logo do tenant aparece na navbar
- Cores personalizáveis (via settings JSON)
- Painel `/admin/tenants` funcional
