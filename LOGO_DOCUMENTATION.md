# Documentação do Sistema de Logotipos

Este documento explica como o sistema de logotipos funciona no CRM 3K e como utilizá-lo em diferentes partes da aplicação.

## Visão Geral

O sistema permite que cada tenant tenha seu próprio logotipo personalizado, que substitui o texto "CRM 3K" em várias partes da aplicação.

## Upload do Logotipo

### Via Configurações da Empresa

1. Acesse **Configurações da Empresa** no menu
2. Na seção "Logotipo da Empresa", clique em "Escolher arquivo"
3. Selecione uma imagem (PNG, JPG, GIF recomendados)
4. Clique em "Salvar Configurações"

### Requisitos da Imagem

- **Formatos aceitos**: PNG, JPG, JPEG, GIF
- **Tamanho recomendado**: 400x120 pixels (proporção 10:3)
- **Tamanho máximo**: 5MB
- **Fundo transparente**: Recomendado para PNG

## Onde o Logotipo Aparece

### 1. **Sidebar (Menu Lateral)**
- Localização: Topo da sidebar esquerda
- Tamanho: Small (40px de altura)
- Fallback: Texto "CRM 3K"

### 2. **Tela de Login**
- Localização: Centro do card de login
- Tamanho: Medium (80px de altura)
- Fallback: Nome da empresa ou "CRM 3K"
- **Nota**: Também aparece como marca d'água no fundo (opacidade 5%)

### 3. **Tela de Subscrição Expirada**
- Localização: Cabeçalho do card
- Tamanho: Medium (80px de altura)
- Fallback: Ícone de aviso triangular
- **Nota**: Logo é invertido para branco no fundo vermelho

### 4. **PDFs Gerados**
- Localização: Cabeçalho do documento
- Tamanho: Conforme BasePdf
- Aparece em:
  - Orçamentos (EstimatePdf)
  - Faturas (InvoicePdf)
  - Relatórios

### 5. **Emails**
- Localização: Cabeçalho do email
- Tamanho: Conforme template
- Aparece em:
  - Emails de orçamento
  - Emails de subscrição
  - Outros emails transacionais

## Helpers Disponíveis

### `tenant_logo(options = {})`

Exibe apenas o logotipo do tenant (se disponível).

**Opções:**
- `size`: Tamanho do logo
  - `:small` - 40px de altura (padrão para sidebar)
  - `:medium` - 80px de altura (padrão para telas)
  - `:large` - 120px de altura (padrão para impressão)
  - String customizada (ex: `'60px'`)
- `fallback`: Texto a exibir se não houver logo (padrão: `'CRM 3K'`)
- `style`: CSS inline adicional
- `class`: Classes CSS adicionais

**Exemplos:**

```erb
<!-- Logo pequeno na sidebar -->
<%= tenant_logo(size: :small) %>

<!-- Logo médio com classe customizada -->
<%= tenant_logo(size: :medium, class: 'my-logo-class') %>

<!-- Logo com estilo customizado -->
<%= tenant_logo(size: '100px', style: 'border-radius: 50%;') %>

<!-- Logo com fallback customizado -->
<%= tenant_logo(size: :large, fallback: 'Minha Empresa') %>
```

### `tenant_branding(options = {})`

Exibe o logo se disponível, ou o nome da empresa, ou fallback.

**Opções:** Mesmas de `tenant_logo`

**Exemplos:**

```erb
<!-- Exibe logo ou nome da empresa -->
<%= tenant_branding(size: :small) %>

<!-- Com fallback customizado -->
<%= tenant_branding(size: :medium, fallback: 'Sistema CRM') %>
```

## Uso em Diferentes Contextos

### Em Views (ERB)

```erb
<!-- Sidebar -->
<div class="sidebar-logo">
  <%= link_to root_path do %>
    <%= tenant_branding(size: :small) %>
  <% end %>
</div>

<!-- Cabeçalho de página -->
<div class="page-header">
  <%= tenant_logo(size: :medium, class: 'company-logo') %>
  <h1>Bem-vindo</h1>
</div>

<!-- Footer -->
<footer>
  <p>Powered by <%= tenant_branding(size: :small) %></p>
</footer>
```

### Em PDFs (Prawn)

Os PDFs usam o BasePdf que já inclui o logo automaticamente no cabeçalho.

```ruby
class MeuPdf < BasePdf
  def initialize(objeto)
    super(objeto.tenant)
    @objeto = objeto
  end

  def generate
    Prawn::Document.new do |pdf|
      add_company_header(pdf)  # Já inclui o logo
      # Seu conteúdo aqui
    end.render
  end
end
```

### Em Emails (Mailers)

Use o helper normalmente nas views de email:

```erb
<!-- app/views/meu_mailer/meu_email.html.erb -->
<div style="text-align: center;">
  <%= tenant_logo(size: :medium) %>
</div>

<p>Prezado cliente...</p>
```

## Verificação Manual

Para verificar se o logotipo está configurado:

```ruby
# No console Rails
tenant = Tenant.first
company_setting = tenant.company_setting

# Verificar se existe logo
company_setting&.logo&.attached?
# => true ou false

# Obter URL do logo
url_for(company_setting.logo) if company_setting&.logo&.attached?
# => URL da imagem
```

## Estilos CSS Recomendados

### Para Logos no Fundo Escuro

```css
.logo-dark-bg {
  filter: brightness(0) invert(1);
  /* Converte logo escuro para branco */
}
```

### Para Logos Responsivos

```css
.responsive-logo {
  max-width: 100%;
  height: auto;
  object-fit: contain;
}
```

## Troubleshooting

### Logo não aparece

1. Verificar se o logo foi enviado:
   ```ruby
   Tenant.first.company_setting&.logo&.attached?
   ```

2. Verificar permissões do Active Storage:
   ```bash
   ls -la storage/
   ```

3. Verificar configuração do Active Storage em `config/storage.yml`

### Logo aparece distorcido

- Certifique-se de usar `object-fit: contain` no CSS
- Verifique as dimensões originais da imagem
- Considere redimensionar a imagem original

### Logo não aparece em PDFs

1. Verificar se o BasePdf está sendo usado
2. Verificar se o logo está acessível:
   ```ruby
   ActiveStorage::Blob.service.path_for(logo.key)
   ```

### Logo não aparece em Emails

1. Verificar se a URL do logo é absoluta
2. Verificar configuração de `asset_host` em produção
3. Usar `url_for(logo)` em vez de `image_tag` se necessário

## Melhores Práticas

1. **Formato**: Use PNG com fundo transparente
2. **Dimensões**: 400x120px (proporção 10:3) é ideal
3. **Tamanho**: Mantenha abaixo de 200KB para performance
4. **Cores**: Logo deve funcionar bem em fundos claros e escuros
5. **Simplicidade**: Logos simples escalam melhor em diferentes tamanhos
6. **Teste**: Sempre teste o logo em:
   - Sidebar (pequeno)
   - Tela de login (médio)
   - PDFs (impressão)
   - Emails (diferentes clientes)

## Exemplo Completo

```erb
<!-- Navbar com logo -->
<nav class="navbar">
  <div class="navbar-brand">
    <%= link_to root_path do %>
      <%= tenant_branding(size: :small) %>
    <% end %>
  </div>
</nav>

<!-- Card de boas-vindas com logo -->
<div class="welcome-card">
  <div class="text-center">
    <%= tenant_logo(size: :large, class: 'mb-4') %>
    <h2>Bem-vindo ao <%= current_user.tenant.company_setting&.company_name || 'CRM 3K' %></h2>
  </div>
</div>

<!-- Footer com branding -->
<footer class="app-footer">
  <small>
    &copy; 2025 <%= tenant_branding(size: :small) %>.
    Todos os direitos reservados.
  </small>
</footer>
```

## Migração de Tenants Antigos

Se você já tem tenants sem logo configurado:

```ruby
# Eles automaticamente mostrarão o fallback
# Não é necessário nenhuma migração
```

## Configuração para Produção

Certifique-se de configurar o Active Storage corretamente:

```ruby
# config/environments/production.rb
config.active_storage.service = :amazon  # ou :google, :azure
config.action_mailer.asset_host = 'https://seu-dominio.com'
```

---

**Documentação criada em:** 24/12/2025
**Última atualização:** 24/12/2025
