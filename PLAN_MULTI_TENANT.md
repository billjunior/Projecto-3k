# PLANO DE IMPLEMENTAÇÃO - CRM 3K MULTI-TENANT

## ANÁLISE DO SISTEMA ATUAL

### O que já existe:
✓ **Autenticação**: Devise configurado
✓ **Autorização**: Pundit instalado (mas sem policies)
✓ **Clientes**: Modelo Customer (particular/empresa)
✓ **Produtos**: Com price_rules por quantidade
✓ **Orçamentos**: Com workflow de aprovação (rascunho → pendente → aprovado/recusado)
✓ **Trabalhos**: Jobs gerados de orçamentos aprovados
✓ **Faturas**: Com pagamentos parciais
✓ **Tarefas**: Polimórficas (relacionadas a qualquer entidade)
✓ **Cyber Café**: LAN machines e sessões
✓ **Roles**: Enum (admin, atendente, producao, financeiro)

### O que precisa ser adicionado:
✗ Multi-tenancy (isolamento de dados)
✗ Modelo Tenant com subscrição
✗ Leads (pré-clientes)
✗ Oportunidades (pipeline de vendas)
✗ Contatos múltiplos por cliente
✗ Comunicações (emails, chamadas)
✗ Branding por tenant (logotipo, cores)
✗ Roles configuráveis por tenant
✗ Pipeline Kanban visual

---

## DECISÕES ARQUITETURAIS

### 1. Estratégia Multi-Tenant: **Row-Level (tenant_id)**

**Escolha**: Adicionar coluna `tenant_id` a todas as tabelas

**Razões**:
- ✅ Mais simples de implementar
- ✅ Fácil de fazer backup por tenant
- ✅ Melhor performance para poucos tenants (<100)
- ✅ Migrations mais simples
- ✅ Facilita queries cross-tenant (relatórios administrativos)
- ✅ Um único schema PostgreSQL

**Alternativa descartada**: Schema-based (Apartment gem)
- ❌ Mais complexo
- ❌ Dificulta migrations
- ❌ Problema com shared tables (produtos?)

### 2. Gems Adicionais Necessárias

```ruby
# Multi-tenancy
gem 'acts_as_tenant'  # Scoping automático por tenant

# File uploads (para logotipos)
gem 'active_storage'  # Já vem no Rails 7

# PDF generation
gem 'prawn'
gem 'prawn-table'

# Kanban UI (opcional, pode ser só JS)
# Turbo/Stimulus já está instalado - suficiente para drag & drop
```

### 3. Arquitetura de Dados

#### Novos Modelos:

**Tenant** (Company)
- name (string)
- subdomain (string, unique) - para futuro multi-domain
- status (enum: active, expired, suspended)
- subscription_start (date)
- subscription_end (date)
- settings (jsonb) - cores, idioma, moeda, impostos
- logo (active_storage)

**Lead**
- tenant_id
- name
- email, phone, company
- source (web, telefone, referência, etc)
- classification (hot, warm, cold)
- assigned_to_user_id
- converted_to_customer_id (quando vira cliente)
- converted_at

**Opportunity**
- tenant_id
- customer_id (obrigatório)
- lead_id (opcional, origem)
- title
- description
- value (decimal)
- probability (integer 0-100)
- stage (enum: new, qualified, proposal, negotiation, won, lost)
- expected_close_date
- actual_close_date
- won_lost_reason
- assigned_to_user_id
- created_by_user_id

**Contact** (múltiplos por customer)
- tenant_id
- customer_id
- name
- email
- phone
- position (cargo)
- is_primary (boolean)

**Communication**
- tenant_id
- related (polymorphic: Customer, Lead, Opportunity)
- communication_type (email, call, meeting, note)
- subject
- body
- user_id (quem registrou)
- occurred_at

**Role** (roles configuráveis)
- tenant_id
- name (Director, Comercial, etc)
- permissions (jsonb) - { customers: {read: true, write: true}, ... }

#### Alterações em Modelos Existentes:

Adicionar `tenant_id` a TODAS as tabelas:
- users (tenant_id + role_id em vez de enum)
- customers
- products
- estimates
- jobs
- invoices
- tasks
- lan_machines
- lan_sessions
- payments
- price_rules
- estimate_items
- job_items
- invoice_items
- job_files

---

## PLANO DE IMPLEMENTAÇÃO

### FASE 1: Fundação Multi-Tenant (Essencial)

**1.1. Criar modelo Tenant**
```bash
rails g model Tenant name:string subdomain:string status:integer \
  subscription_start:date subscription_end:date settings:jsonb
```

**1.2. Adicionar tenant_id a User**
```bash
rails g migration AddTenantToUsers tenant:references
```

**1.3. Adicionar tenant_id a TODAS as tabelas existentes**
```bash
rails g migration AddTenantToAllTables
# Migration customizada para adicionar tenant_id a todas as tabelas
```

**1.4. Configurar acts_as_tenant**
- Adicionar `gem 'acts_as_tenant'`
- Configurar `ApplicationRecord` com `acts_as_tenant :tenant`
- Adicionar `set_current_tenant` no ApplicationController
- Garantir scoping automático em todas as queries

**1.5. Atualizar Devise**
- Adicionar validação de tenant no login
- Bloquear acesso se tenant expirado
- Scope users por tenant

**1.6. Seed com Tenant padrão**
- Criar tenant "CRM 3K Demo"
- Migrar dados existentes para esse tenant
- Criar usuário admin

### FASE 2: Subscrição e Branding

**2.1. Lógica de Subscrição**
- Concern `TenantSubscription` com métodos:
  - `active?`
  - `expired?`
  - `days_until_expiration`
  - `block_access!`
- Before_action no ApplicationController para verificar subscrição
- Página de "Subscrição Expirada"

**2.2. Branding**
- Active Storage para logo
- Settings JSONB para cores: `{primary_color: '#..', secondary_color: '#..'}`
- Helper `tenant_logo_tag` e `tenant_color(type)`
- CSS dinâmico via stylesheet controller

**2.3. Super Admin**
- Controller `Admin::TenantsController` (namespace)
- Rota: `/admin/tenants`
- Apenas users com `super_admin: true`
- CRUD de tenants
- Extend/renew subscription

### FASE 3: Leads e Oportunidades

**3.1. Modelo Lead**
```bash
rails g model Lead tenant:references name:string email:string phone:string \
  company:string source:string classification:integer \
  assigned_to_user:references:index \
  converted_to_customer:references:index converted_at:datetime
```

**3.2. Modelo Opportunity**
```bash
rails g model Opportunity tenant:references customer:references \
  lead:references title:string value:decimal probability:integer \
  stage:integer expected_close_date:date actual_close_date:date \
  won_lost_reason:text assigned_to_user:references created_by_user:references
```

**3.3. Controllers e Views**
- `LeadsController` com conversão para cliente
- `OpportunitiesController` com Kanban view
- Formulários com select2 ou tom-select

### FASE 4: Pipeline Kanban

**4.1. View Kanban**
- Usar Stimulus controller para drag & drop
- HTML com colunas por stage
- SortableJS ou Dragula.js
- Update via Turbo Frame

**4.2. Stages configuráveis?**
- Opção 1: Enum fixo (mais simples)
- Opção 2: Modelo `Stage` por tenant (mais flexível)
- **Recomendação**: Enum fixo por agora, configurável depois

**4.3. Métricas no Dashboard**
- Cards com total por stage
- Previsão de receita (sum de opportunities com probabilidade)
- Taxa de conversão

### FASE 5: Contatos e Comunicação

**5.1. Modelo Contact**
```bash
rails g model Contact tenant:references customer:references \
  name:string email:string phone:string position:string is_primary:boolean
```

**5.2. Modelo Communication**
```bash
rails g model Communication tenant:references related:references{polymorphic} \
  communication_type:integer subject:string body:text \
  user:references occurred_at:datetime
```

**5.3. Histórico Unificado**
- Partial `_timeline.html.erb` mostrando:
  - Oportunidades
  - Orçamentos
  - Trabalhos
  - Faturas
  - Comunicações
- Ordem cronológica reversa

### FASE 6: Roles e Permissões

**6.1. Modelo Role**
```bash
rails g model Role tenant:references name:string permissions:jsonb
```

**6.2. Atualizar User**
```bash
rails g migration ChangeUserRoleToRoleId
# Remove enum role, add role_id:references
```

**6.3. Pundit Policies**
- Criar policy para cada resource
- Verificar `user.role.permissions[action]`
- Aplicar `authorize @resource` em controllers

**6.4. Seeding de Roles padrão**
```ruby
# Diretor: tudo
# Administrador: tudo exceto settings
# Comercial: leads, opportunities, customers, estimates
# Vendas: customers, estimates (read-only)
# Produção: jobs (read/write), estimates (read)
# Técnico: jobs, invoices (read)
```

### FASE 7: Relatórios e KPIs

**7.1. Dashboard Expandido**
- Leads por mês (chart.js ou chartkick)
- Oportunidades por fase
- Conversão por vendedor
- Receita prevista vs real
- Trabalhos por status

**7.2. Filtros**
- Date range picker
- Por utilizador
- Por cliente

---

## ORDEM DE IMPLEMENTAÇÃO RECOMENDADA

### Sprint 1 (Essencial - 1 semana)
1. ✅ Adicionar gem acts_as_tenant
2. ✅ Criar modelo Tenant
3. ✅ Migrar tenant_id para todas as tabelas
4. ✅ Configurar scoping global
5. ✅ Seed com tenant demo
6. ✅ Testes de isolamento

### Sprint 2 (Subscrição - 3 dias)
1. ✅ Lógica de subscrição
2. ✅ Bloqueio de acesso
3. ✅ Active Storage para logo
4. ✅ Settings para cores
5. ✅ Super admin panel básico

### Sprint 3 (Leads & Opportunities - 5 dias)
1. ✅ Modelos Lead e Opportunity
2. ✅ Controllers e views
3. ✅ Conversão Lead → Customer
4. ✅ Conversão Opportunity → Estimate
5. ✅ Formulários e validações

### Sprint 4 (Pipeline Kanban - 3 dias)
1. ✅ View Kanban com Stimulus
2. ✅ Drag & drop funcional
3. ✅ Update de stage via AJAX
4. ✅ Indicadores por coluna

### Sprint 5 (Contatos & Comunicação - 4 dias)
1. ✅ Modelo Contact
2. ✅ Modelo Communication
3. ✅ Timeline unificado
4. ✅ Formulário de registro de chamadas/emails

### Sprint 6 (Roles & Permissions - 5 dias)
1. ✅ Modelo Role
2. ✅ Migrar User.role para role_id
3. ✅ Criar Pundit policies
4. ✅ UI de configuração de roles
5. ✅ Seed de roles padrão

### Sprint 7 (Relatórios - 3 dias)
1. ✅ Dashboard com charts
2. ✅ Filtros por data e usuário
3. ✅ Export CSV/PDF

---

## MIGRATIONS CRÍTICAS

### 1. Criar Tenant
```ruby
class CreateTenants < ActiveRecord::Migration[7.1]
  def change
    create_table :tenants do |t|
      t.string :name, null: false
      t.string :subdomain, null: false, index: {unique: true}
      t.integer :status, default: 0, null: false
      t.date :subscription_start
      t.date :subscription_end
      t.jsonb :settings, default: {}
      t.timestamps
    end
  end
end
```

### 2. Adicionar tenant_id a tudo
```ruby
class AddTenantToAllTables < ActiveRecord::Migration[7.1]
  def change
    tables = [
      :users, :customers, :products, :estimates, :estimate_items,
      :jobs, :job_items, :job_files, :invoices, :invoice_items,
      :payments, :tasks, :lan_machines, :lan_sessions, :price_rules
    ]

    tables.each do |table|
      add_reference table, :tenant, null: false, foreign_key: true,
                    default: 1  # Tenant demo
      add_index table, :tenant_id
    end
  end
end
```

### 3. Criar Leads
```ruby
class CreateLeads < ActiveRecord::Migration[7.1]
  def change
    create_table :leads do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :company
      t.string :source
      t.integer :classification, default: 1  # 0:hot, 1:warm, 2:cold
      t.references :assigned_to_user, foreign_key: {to_table: :users}
      t.references :converted_to_customer, foreign_key: {to_table: :customers}
      t.datetime :converted_at
      t.text :notes
      t.timestamps
    end

    add_index :leads, :classification
    add_index :leads, :converted_at
  end
end
```

### 4. Criar Opportunities
```ruby
class CreateOpportunities < ActiveRecord::Migration[7.1]
  def change
    create_table :opportunities do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :lead, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.decimal :value, precision: 10, scale: 2
      t.integer :probability, default: 50
      t.integer :stage, default: 0, null: false
      # 0:new, 1:qualified, 2:proposal, 3:negotiation, 4:won, 5:lost
      t.date :expected_close_date
      t.date :actual_close_date
      t.text :won_lost_reason
      t.references :assigned_to_user, foreign_key: {to_table: :users}
      t.references :created_by_user, foreign_key: {to_table: :users}
      t.timestamps
    end

    add_index :opportunities, :stage
    add_index :opportunities, :expected_close_date
  end
end
```

---

## CONCERNS IMPORTANTES

### TenantScoped (aplicar a todos os modelos)
```ruby
module TenantScoped
  extend ActiveSupport::Concern

  included do
    acts_as_tenant :tenant
    validates :tenant, presence: true
  end
end
```

### TenantSubscription (no modelo Tenant)
```ruby
module TenantSubscription
  extend ActiveSupport::Concern

  def active?
    status == 'active' && (subscription_end.nil? || subscription_end >= Date.today)
  end

  def expired?
    subscription_end.present? && subscription_end < Date.today
  end

  def days_until_expiration
    return nil if subscription_end.nil?
    (subscription_end - Date.today).to_i
  end

  def expiring_soon?
    days = days_until_expiration
    days.present? && days > 0 && days <= 15
  end
end
```

---

## TESTES DE ISOLAMENTO CRÍTICOS

```ruby
# test/models/tenant_scoping_test.rb
class TenantScopingTest < ActiveSupport::TestCase
  test "users only see their tenant's customers" do
    tenant1 = tenants(:one)
    tenant2 = tenants(:two)

    ActsAsTenant.with_tenant(tenant1) do
      assert_equal 5, Customer.count
      customer = Customer.create!(name: "Test", customer_type: "particular")
      assert_equal tenant1.id, customer.tenant_id
    end

    ActsAsTenant.with_tenant(tenant2) do
      assert_equal 3, Customer.count  # Não vê os 5 do tenant1
    end
  end

  test "cannot access another tenant's data" do
    tenant1 = tenants(:one)
    tenant2 = tenants(:two)

    customer = nil
    ActsAsTenant.with_tenant(tenant1) do
      customer = Customer.create!(name: "Test", customer_type: "particular")
    end

    ActsAsTenant.with_tenant(tenant2) do
      assert_raises(ActiveRecord::RecordNotFound) do
        Customer.find(customer.id)
      end
    end
  end
end
```

---

## RISCOS E MITIGAÇÕES

### Risco 1: Performance com muitos tenants
- **Mitigação**: Índices em tenant_id + timestamps
- **Monitorar**: Queries com EXPLAIN ANALYZE
- **Alternativa futura**: Partition tables por tenant_id

### Risco 2: Data leak entre tenants
- **Mitigação**: Testes automatizados de isolamento
- **Revisão**: Todos controllers com authorize
- **Auditoria**: Log de acessos cross-tenant

### Risco 3: Migrations complexas
- **Mitigação**: Testar em staging primeiro
- **Backup**: Antes de cada migration de produção
- **Rollback plan**: Script de reversão preparado

---

## CHECKLIST DE ACEITAÇÃO

### Multi-Tenancy
- [ ] Cada tenant vê apenas seus dados
- [ ] Impossível acessar dados de outro tenant via URL/API
- [ ] Super admin pode ver todos os tenants

### Subscrição
- [ ] Tenant expirado não consegue fazer login
- [ ] Aviso 15 dias antes de expirar
- [ ] Super admin pode renovar subscrição

### Leads & Pipeline
- [ ] Criar lead manual
- [ ] Converter lead em cliente
- [ ] Criar oportunidade linkada a cliente
- [ ] Arrastar oportunidade entre fases (Kanban)
- [ ] Marcar oportunidade como ganha/perdida

### Branding
- [ ] Upload de logotipo exibido em todas as páginas
- [ ] Logo aparece nos PDFs de orçamentos
- [ ] Cores personalizáveis aplicadas na UI

### Roles
- [ ] Admin pode criar roles personalizados
- [ ] Permissões por módulo funcionam
- [ ] Usuário sem permissão vê 403

### Relatórios
- [ ] Dashboard mostra leads por mês
- [ ] Pipeline mostra valor total por fase
- [ ] Conversão por vendedor calculada

---

## PRÓXIMOS PASSOS

Após aprovação deste plano:
1. Confirmar prioridades (todas as 7 sprints ou MVP menor?)
2. Decidir: implementar tudo ou começar pelo essencial?
3. Validar gems adicionais (acts_as_tenant, prawn)
4. Executar Sprint 1 (fundação multi-tenant)
