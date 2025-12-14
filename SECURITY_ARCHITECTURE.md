# Arquitetura de Segurança CRM 3K - Baseada em OWASP Top 10

## Visão Geral
Este documento descreve a arquitetura de segurança implementada no CRM 3K, seguindo as melhores práticas do OWASP Top 10 (2021).

## Estrutura de Roles e Permissões

### Roles Definidos

1. **Director (super_admin: true)**
   - Acesso total ao CRM
   - Acesso total ao Cyber Café
   - Pode gerenciar usuários e configurações
   - Pode ver todos os relatórios

2. **Directora Financeira (admin: true, department: financial)**
   - Acesso total ao CRM
   - Acesso a relatórios financeiros
   - Acesso a todos os módulos financeiros
   - Sem acesso ao Cyber Café

3. **Assistente Comercial (role: commercial)**
   - Acesso completo a CRM (Leads, Oportunidades, Clientes)
   - Acesso a Orçamentos e Trabalhos
   - Acesso a criação de Faturas
   - Sem acesso ao Cyber Café
   - Sem acesso a relatórios financeiros detalhados

4. **Técnico Cyber Café (role: cyber_tech)**
   - Acesso EXCLUSIVO ao Cyber Café
   - Sem acesso ao CRM principal
   - Login separado via /cyber/login
   - Pode gerenciar máquinas, sessões, inventário do cyber
   - Acesso a receitas diárias e cursos de formação

5. **Atendente (role: attendant)**
   - Acesso limitado a clientes (leitura)
   - Pode criar orçamentos
   - Sem acesso a faturas ou relatórios
   - Sem acesso ao Cyber Café

6. **Produção (role: production)**
   - Acesso apenas a Trabalhos (Jobs)
   - Pode atualizar status de trabalhos
   - Upload de arquivos de trabalho
   - Sem acesso financeiro ou Cyber Café

## Separação de Acesso CRM vs Cyber Café

### CRM (Acesso via /users/sign_in)
- Disponível para: Director, Directora Financeira, Assistente Comercial, Atendente, Produção
- Namespace: Sem namespace (padrão)
- Layout: application.html.erb

### Cyber Café (Acesso via /cyber/login)
- Disponível APENAS para: Director e Técnico Cyber Café
- Namespace: Cyber::
- Layout: cyber/application.html.erb
- Sessões separadas
- Controllers independentes

## OWASP Top 10 - Implementações

### A01:2021 – Broken Access Control
**Implementação:**
- Pundit para autorização granular em TODOS os controllers
- Policies específicas para cada modelo
- Verificação de tenant_id em todas as queries
- Scope automático por tenant (acts_as_tenant)
- Before_action :authorize em todos os controllers

### A02:2021 – Cryptographic Failures
**Implementação:**
- Devise para autenticação (bcrypt para passwords)
- Encrypted credentials do Rails para secrets
- Force SSL em produção
- Secure cookies (httponly, secure flags)
- Token CSRF em todos os formulários

### A03:2021 – Injection
**Implementação:**
- ActiveRecord para prevenir SQL Injection
- Strong Parameters em todos os controllers
- Sanitização de HTML com sanitize helper
- Content Security Policy (CSP) configurado
- Validação de tipos de arquivo em uploads

### A04:2021 – Insecure Design
**Implementação:**
- Separação clara de responsabilidades (CRM vs Cyber)
- Princípio do menor privilégio
- Roles bem definidos com permissões granulares
- Auditoria de ações sensíveis (logs)
- Rate limiting para login

### A05:2021 – Security Misconfiguration
**Implementação:**
- Remove header X-Powered-By
- Configuração segura do Devise
- Session timeout configurado
- Previne directory listing
- Error pages customizadas (sem stack trace em produção)

### A06:2021 – Vulnerable Components
**Implementação:**
- Bundle audit para verificar gems vulneráveis
- Dependências atualizadas regularmente
- Apenas gems confiáveis do RubyGems
- Review de segurança antes de adicionar gems

### A07:2021 – Identification and Authentication Failures
**Implementação:**
- Devise com configurações seguras
- Lockable após 5 tentativas falhas
- Password strength validation (min 8 chars, complexidade)
- Email confirmation
- Secure session management
- Remember me com token seguro
- Logout em todas as sessões ao trocar senha

### A08:2021 – Software and Data Integrity Failures
**Implementação:**
- Integridade de sessão (signed cookies)
- CSRF protection habilitado
- Subresource Integrity (SRI) para CDNs
- Verificação de checksums em uploads
- Logging de mudanças críticas

### A09:2021 – Security Logging and Monitoring
**Implementação:**
- Lograge para logs estruturados
- Audit trail para ações administrativas
- Login attempts logging
- Failed authorization attempts logging
- Alerts para atividades suspeitas

### A10:2021 – Server-Side Request Forgery
**Implementação:**
- Whitelist de URLs permitidos
- Sem permitir input de usuário em requests HTTP
- Validação de redirecionamentos
- Sanitização de parâmetros de URL

## Estrutura de Banco de Dados

### Tabela: users
```ruby
- tenant_id (references tenants)
- email (encrypted, unique per tenant)
- encrypted_password
- role (enum: commercial, cyber_tech, attendant, production)
- department (enum: financial, commercial, technical, null)
- admin (boolean, default: false)
- super_admin (boolean, default: false)
- failed_attempts (integer, default: 0)
- locked_at (datetime)
- last_sign_in_at (datetime)
- current_sign_in_at (datetime)
- sign_in_count (integer)
- confirmation_token
- confirmed_at
```

## Fluxo de Autenticação

### Login CRM
1. User acessa /users/sign_in
2. Devise valida credenciais
3. Verifica se NOT cyber_tech? (cyber_tech redireciona para /cyber/login)
4. Cria sessão com tenant_id
5. Redireciona para dashboard apropriado

### Login Cyber Café
1. User acessa /cyber/login
2. Valida se user.cyber_tech? OR user.super_admin?
3. Cria sessão separada no namespace Cyber
4. Redireciona para /cyber/dashboard
5. Aplica layout e policies do namespace Cyber

## Policies (Pundit)

Cada modelo tem uma Policy que define:
- index? - Pode listar?
- show? - Pode ver?
- create? - Pode criar?
- update? - Pode editar?
- destroy? - Pode deletar?
- manage? - Acesso administrativo?

### Exemplo: CustomerPolicy
```ruby
def index?
  !user.cyber_tech?
end

def create?
  user.admin? || user.super_admin? || user.commercial?
end

def update?
  user.admin? || user.super_admin? || user.commercial? || record.created_by == user
end

def destroy?
  user.admin? || user.super_admin?
end
```

## Testes de Segurança

1. **Isolation Tests**: Verificar que users de um tenant não veem dados de outro
2. **Authorization Tests**: Verificar que cada role só acessa o permitido
3. **CSRF Tests**: Verificar proteção contra CSRF
4. **SQL Injection Tests**: Tentar injeção em formulários
5. **XSS Tests**: Verificar sanitização de HTML

## Monitoring e Alertas

1. **Failed Login Attempts**: Alert após 10 tentativas falhadas
2. **Unauthorized Access Attempts**: Log e alerta
3. **Bulk Data Exports**: Requer aprovação admin
4. **Password Changes**: Notificação por email
5. **New User Creation**: Notificação para admins

## Princípio do Menor Privilégio

- Cada usuário tem apenas as permissões necessárias para seu trabalho
- Acesso é negado por padrão (whitelist approach)
- Elevação de privilégios requer autenticação adicional
- Sessões expiram após 30 minutos de inatividade
- Re-autenticação necessária para ações sensíveis

## Conclusão

Esta arquitetura garante:
- ✅ Separação total entre CRM e Cyber Café
- ✅ Autorização granular baseada em roles
- ✅ Proteção contra OWASP Top 10
- ✅ Auditoria completa de ações
- ✅ Isolamento de dados por tenant
- ✅ Segurança em profundidade (defense in depth)
