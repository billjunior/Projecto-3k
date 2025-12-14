# Exemplos de Autorização em Views

Este documento mostra como usar os helpers de autorização nas views do CRM 3K.

---

## 1. Helpers Disponíveis

### Verificação de Permissões

```ruby
can_view?(resource)         # Pode visualizar?
can_edit?(resource)         # Pode editar?
can_delete?(resource)       # Pode deletar?
can_create?(ResourceClass)  # Pode criar?
can_manage?(resource)       # Tem acesso admin?
```

### Verificação de Acesso a Módulos

```ruby
can_access_crm?      # Pode acessar CRM?
can_access_cyber?    # Pode acessar Cyber Café?
```

### Verificação de Roles

```ruby
admin?               # É admin ou super_admin?
super_admin?         # É super_admin?
financial_director?  # É directora financeira?
```

---

## 2. Exemplos de Uso em Views

### 2.1 Index - Lista de Clientes

**app/views/customers/index.html.erb**

```erb
<div class="container">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Clientes</h1>

    <!-- Botão de criar apenas se autorizado -->
    <% if can_create?(Customer) %>
      <%= link_to "Novo Cliente", new_customer_path, class: "btn btn-primary" %>
    <% end %>
  </div>

  <table class="table">
    <thead>
      <tr>
        <th>Nome</th>
        <th>Tipo</th>
        <th>Email</th>
        <th>Telefone</th>
        <th>Ações</th>
      </tr>
    </thead>
    <tbody>
      <% @customers.each do |customer| %>
        <tr>
          <td><%= customer.name %></td>
          <td><%= customer.customer_type %></td>
          <td><%= customer.email %></td>
          <td><%= customer.phone %></td>
          <td>
            <!-- Mostrar botões apenas se autorizado -->
            <% if can_view?(customer) %>
              <%= link_to "Ver", customer_path(customer), class: "btn btn-sm btn-info" %>
            <% end %>

            <% if can_edit?(customer) %>
              <%= link_to "Editar", edit_customer_path(customer), class: "btn btn-sm btn-warning" %>
            <% end %>

            <% if can_delete?(customer) %>
              <%= link_to "Deletar", customer_path(customer),
                  method: :delete,
                  data: { confirm: "Tem certeza?" },
                  class: "btn btn-sm btn-danger" %>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### 2.2 Show - Detalhes do Cliente

**app/views/customers/show.html.erb**

```erb
<div class="container">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1><%= @customer.name %></h1>

    <div>
      <%= link_to "Voltar", customers_path, class: "btn btn-secondary" %>

      <!-- Botões de ação apenas se autorizado -->
      <% if can_edit?(@customer) %>
        <%= link_to "Editar", edit_customer_path(@customer), class: "btn btn-warning" %>
      <% end %>

      <% if can_delete?(@customer) %>
        <%= link_to "Deletar", customer_path(@customer),
            method: :delete,
            data: { confirm: "Tem certeza?" },
            class: "btn btn-danger" %>
      <% end %>
    </div>
  </div>

  <div class="card">
    <div class="card-body">
      <h5 class="card-title">Informações</h5>
      <p><strong>Tipo:</strong> <%= @customer.customer_type %></p>
      <p><strong>Email:</strong> <%= @customer.email %></p>
      <p><strong>Telefone:</strong> <%= @customer.phone %></p>
      <p><strong>Endereço:</strong> <%= @customer.address %></p>
    </div>
  </div>

  <!-- Seções relacionadas apenas se autorizado -->
  <% if can_view?(Invoice.new) %>
    <div class="card mt-3">
      <div class="card-body">
        <h5 class="card-title">Faturas</h5>
        <!-- Lista de faturas -->
      </div>
    </div>
  <% end %>
</div>
```

### 2.3 Layout Principal - Menu de Navegação

**app/views/layouts/application.html.erb**

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>CRM 3K</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
      <div class="container-fluid">
        <%= link_to "CRM 3K", root_path, class: "navbar-brand" %>

        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto">
            <!-- Menu CRM - apenas se pode acessar -->
            <% if can_access_crm? %>
              <li class="nav-item dropdown">
                <a class="nav-link dropdown-toggle" href="#" data-bs-toggle="dropdown">
                  CRM
                </a>
                <ul class="dropdown-menu">
                  <li><%= link_to "Clientes", customers_path, class: "dropdown-item" %></li>
                  <li><%= link_to "Produtos", products_path, class: "dropdown-item" %></li>
                  <li><%= link_to "Orçamentos", estimates_path, class: "dropdown-item" %></li>
                  <li><%= link_to "Trabalhos", jobs_path, class: "dropdown-item" %></li>

                  <!-- Faturas apenas para quem tem acesso -->
                  <% if can_view?(Invoice.new) %>
                    <li><%= link_to "Faturas", invoices_path, class: "dropdown-item" %></li>
                  <% end %>

                  <!-- Leads/Oportunidades apenas para commercial -->
                  <% if can_view?(Lead.new) %>
                    <li><hr class="dropdown-divider"></li>
                    <li><%= link_to "Leads", leads_path, class: "dropdown-item" %></li>
                    <li><%= link_to "Oportunidades", opportunities_path, class: "dropdown-item" %></li>
                  <% end %>
                </ul>
              </li>
            <% end %>

            <!-- Menu Cyber Café - apenas se pode acessar -->
            <% if can_access_cyber? %>
              <li class="nav-item dropdown">
                <a class="nav-link dropdown-toggle" href="#" data-bs-toggle="dropdown">
                  Cyber Café
                </a>
                <ul class="dropdown-menu">
                  <li><%= link_to "Máquinas", lan_machines_path, class: "dropdown-item" %></li>
                  <li><%= link_to "Sessões", lan_sessions_path, class: "dropdown-item" %></li>
                  <li><%= link_to "Inventário", inventory_items_path, class: "dropdown-item" %></li>
                  <li><%= link_to "Receitas Diárias", daily_revenues_path, class: "dropdown-item" %></li>
                  <li><%= link_to "Cursos", training_courses_path, class: "dropdown-item" %></li>
                </ul>
              </li>
            <% end %>

            <!-- Relatórios apenas para admin -->
            <% if admin? %>
              <li class="nav-item">
                <%= link_to "Relatórios", reports_path, class: "nav-link" %>
              </li>
            <% end %>

            <!-- Configurações apenas para super_admin -->
            <% if super_admin? %>
              <li class="nav-item">
                <%= link_to "Configurações", company_settings_path, class: "nav-link" %>
              </li>
            <% end %>
          </ul>

          <ul class="navbar-nav">
            <li class="nav-item dropdown">
              <a class="nav-link dropdown-toggle" href="#" data-bs-toggle="dropdown">
                <%= current_user.name %>
              </a>
              <ul class="dropdown-menu dropdown-menu-end">
                <li><%= link_to "Perfil", edit_user_registration_path, class: "dropdown-item" %></li>
                <li><hr class="dropdown-divider"></li>
                <li>
                  <%= link_to "Sair", destroy_user_session_path,
                      data: { turbo_method: :delete },
                      class: "dropdown-item" %>
                </li>
              </ul>
            </li>
          </ul>
        </div>
      </div>
    </nav>

    <div class="container mt-4">
      <!-- Flash messages -->
      <% if notice %>
        <div class="alert alert-success alert-dismissible fade show">
          <%= notice %>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      <% end %>

      <% if alert %>
        <div class="alert alert-danger alert-dismissible fade show">
          <%= alert %>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      <% end %>

      <%= yield %>
    </div>
  </body>
</html>
```

### 2.4 Formulário - Novo/Editar Cliente

**app/views/customers/_form.html.erb**

```erb
<%= form_with(model: customer, local: true) do |form| %>
  <% if customer.errors.any? %>
    <div class="alert alert-danger">
      <h4><%= pluralize(customer.errors.count, "erro") %> impedem que este cliente seja salvo:</h4>
      <ul>
        <% customer.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="mb-3">
    <%= form.label :name, "Nome", class: "form-label" %>
    <%= form.text_field :name, class: "form-control" %>
  </div>

  <div class="mb-3">
    <%= form.label :customer_type, "Tipo", class: "form-label" %>
    <%= form.select :customer_type,
        options_for_select([["Particular", "particular"], ["Empresa", "empresa"]], customer.customer_type),
        {}, class: "form-select" %>
  </div>

  <div class="mb-3">
    <%= form.label :email, "Email", class: "form-label" %>
    <%= form.email_field :email, class: "form-control" %>
  </div>

  <div class="mb-3">
    <%= form.label :phone, "Telefone", class: "form-label" %>
    <%= form.text_field :phone, class: "form-control" %>
  </div>

  <div class="mb-3">
    <%= form.label :address, "Endereço", class: "form-label" %>
    <%= form.text_area :address, rows: 3, class: "form-control" %>
  </div>

  <!-- Campos adicionais apenas para admin -->
  <% if admin? %>
    <div class="mb-3">
      <%= form.label :notes, "Notas Internas (apenas admin)", class: "form-label" %>
      <%= form.text_area :notes, rows: 3, class: "form-control" %>
    </div>
  <% end %>

  <div class="mb-3">
    <%= form.submit class: "btn btn-primary" %>
    <%= link_to "Cancelar", customers_path, class: "btn btn-secondary" %>
  </div>
<% end %>
```

### 2.5 Dashboard

**app/views/dashboard/index.html.erb**

```erb
<div class="container">
  <h1>Dashboard</h1>

  <div class="row">
    <!-- Card CRM -->
    <% if can_access_crm? %>
      <div class="col-md-6">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title">CRM</h5>
            <p class="card-text">Sistema de gestão de clientes e vendas</p>
            <%= link_to "Acessar CRM", customers_path, class: "btn btn-primary" %>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Card Cyber Café -->
    <% if can_access_cyber? %>
      <div class="col-md-6">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title">Cyber Café</h5>
            <p class="card-text">Gestão de máquinas e sessões</p>
            <%= link_to "Acessar Cyber", lan_machines_path, class: "btn btn-success" %>
          </div>
        </div>
      </div>
    <% end %>
  </div>

  <!-- Estatísticas apenas para admin -->
  <% if admin? %>
    <div class="row mt-4">
      <div class="col-md-12">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title">Estatísticas (Admin)</h5>
            <!-- Gráficos e estatísticas -->
          </div>
        </div>
      </div>
    </div>
  <% end %>

  <!-- Relatórios financeiros apenas para financial_director -->
  <% if financial_director? %>
    <div class="row mt-4">
      <div class="col-md-12">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title">Relatórios Financeiros</h5>
            <%= link_to "Ver Relatórios", reports_path, class: "btn btn-info" %>
          </div>
        </div>
      </div>
    </div>
  <% end %>
</div>
```

### 2.6 Ações Customizadas - Aprovar Orçamento

**app/views/estimates/show.html.erb**

```erb
<div class="container">
  <h1>Orçamento #<%= @estimate.id %></h1>

  <div class="card">
    <div class="card-body">
      <p><strong>Cliente:</strong> <%= @estimate.customer.name %></p>
      <p><strong>Status:</strong> <%= @estimate.status %></p>
      <p><strong>Total:</strong> <%= number_to_currency(@estimate.total) %></p>
    </div>
  </div>

  <div class="mt-3">
    <%= link_to "Voltar", estimates_path, class: "btn btn-secondary" %>

    <!-- Editar apenas se autorizado -->
    <% if can_edit?(@estimate) %>
      <%= link_to "Editar", edit_estimate_path(@estimate), class: "btn btn-warning" %>
    <% end %>

    <!-- Aprovar apenas se autorizado (usando policy customizada) -->
    <% if policy(@estimate).approve? %>
      <%= link_to "Aprovar Orçamento",
          approve_estimate_path(@estimate),
          method: :post,
          data: { confirm: "Aprovar este orçamento?" },
          class: "btn btn-success" %>
    <% end %>

    <!-- Deletar apenas se autorizado -->
    <% if can_delete?(@estimate) %>
      <%= link_to "Deletar",
          estimate_path(@estimate),
          method: :delete,
          data: { confirm: "Tem certeza?" },
          class: "btn btn-danger" %>
    <% end %>
  </div>
</div>
```

### 2.7 Tabela de Usuários (Super Admin)

**app/views/users/index.html.erb**

```erb
<% if super_admin? %>
  <div class="container">
    <h1>Gerenciar Usuários</h1>

    <%= link_to "Novo Usuário", new_user_path, class: "btn btn-primary mb-3" %>

    <table class="table">
      <thead>
        <tr>
          <th>Nome</th>
          <th>Email</th>
          <th>Role</th>
          <th>Department</th>
          <th>Admin</th>
          <th>Ações</th>
        </tr>
      </thead>
      <tbody>
        <% @users.each do |user| %>
          <tr>
            <td><%= user.name %></td>
            <td><%= user.email %></td>
            <td><%= user.role %></td>
            <td><%= user.department %></td>
            <td><%= user.admin? ? "Sim" : "Não" %></td>
            <td>
              <%= link_to "Editar", edit_user_path(user), class: "btn btn-sm btn-warning" %>
              <%= link_to "Deletar", user_path(user),
                  method: :delete,
                  data: { confirm: "Tem certeza?" },
                  class: "btn btn-sm btn-danger" %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
<% else %>
  <div class="container">
    <div class="alert alert-danger">
      Apenas super administradores podem gerenciar usuários.
    </div>
    <%= link_to "Voltar ao Dashboard", root_path, class: "btn btn-primary" %>
  </div>
<% end %>
```

---

## 3. Padrões Comuns

### 3.1 Botão Condicional

```erb
<% if can_create?(Resource) %>
  <%= link_to "Criar Novo", new_resource_path, class: "btn btn-primary" %>
<% end %>
```

### 3.2 Link de Ação Condicional

```erb
<% if can_edit?(@resource) %>
  <%= link_to "Editar", edit_resource_path(@resource), class: "btn btn-warning" %>
<% end %>
```

### 3.3 Deletar com Confirmação

```erb
<% if can_delete?(@resource) %>
  <%= link_to "Deletar",
      resource_path(@resource),
      method: :delete,
      data: { confirm: "Tem certeza que deseja deletar?" },
      class: "btn btn-danger" %>
<% end %>
```

### 3.4 Menu Dropdown Condicional

```erb
<% if can_access_crm? %>
  <li class="nav-item dropdown">
    <a class="nav-link dropdown-toggle" href="#" data-bs-toggle="dropdown">
      CRM
    </a>
    <ul class="dropdown-menu">
      <li><%= link_to "Clientes", customers_path, class: "dropdown-item" %></li>
      <!-- Mais itens -->
    </ul>
  </li>
<% end %>
```

### 3.5 Seção Inteira Condicional

```erb
<% if admin? %>
  <div class="admin-section">
    <h3>Área Administrativa</h3>
    <!-- Conteúdo apenas para admins -->
  </div>
<% end %>
```

### 3.6 Verificar Policy Customizada

```erb
<% if policy(@estimate).approve? %>
  <%= link_to "Aprovar", approve_estimate_path(@estimate), class: "btn btn-success" %>
<% end %>
```

---

## 4. Mensagens de Erro Amigáveis

### 4.1 Mostrar Erro de Permissão

**app/views/errors/not_authorized.html.erb**

```erb
<div class="container">
  <div class="alert alert-danger">
    <h4>Acesso Negado</h4>
    <p>Você não tem permissão para executar esta ação.</p>
  </div>

  <%= link_to "Voltar ao Dashboard", root_path, class: "btn btn-primary" %>
</div>
```

### 4.2 Fallback para Páginas Não Autorizadas

```erb
<% if can_view?(@resource) %>
  <!-- Mostrar conteúdo -->
<% else %>
  <div class="alert alert-warning">
    Você não tem permissão para visualizar este conteúdo.
  </div>
<% end %>
```

---

## 5. Checklist de Implementação em Views

Para cada view:

- [ ] Verificar se botões de criar estão protegidos com `can_create?`
- [ ] Verificar se botões de editar estão protegidos com `can_edit?`
- [ ] Verificar se botões de deletar estão protegidos com `can_delete?`
- [ ] Verificar se menus estão protegidos com `can_access_crm?` / `can_access_cyber?`
- [ ] Verificar se seções administrativas estão protegidas com `admin?` ou `super_admin?`
- [ ] Verificar se ações customizadas usam `policy(@resource).custom_action?`
- [ ] Adicionar mensagens de erro amigáveis para acesso negado

---

## 6. Dicas Importantes

1. **Use helpers consistentemente:** Sempre use os helpers de autorização em vez de verificar roles diretamente
2. **Teste com diferentes usuários:** Faça login com cada role e verifique se os menus aparecem corretamente
3. **Fallback gracioso:** Sempre forneça mensagens claras quando o acesso for negado
4. **Performance:** Use `can_view?(Resource.new)` em vez de `can_view?(Resource)` quando verificar classe
5. **Segurança em camadas:** Lembre-se que verificações em views são apenas UI - a segurança real está nas policies e controllers

---

**Boas práticas implementadas com sucesso!**
