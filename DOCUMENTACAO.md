# CRM 3K - Documentação do Sistema
**Sistema de Gestão para Gráfica e CyberCafé Multi-Tenant**

---

## Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Módulos do Sistema](#módulos-do-sistema)
4. [Workflows Principais](#workflows-principais)
5. [Perfis de Utilizador](#perfis-de-utilizador)
6. [Funcionalidades Detalhadas](#funcionalidades-detalhadas)
7. [Acesso ao Sistema](#acesso-ao-sistema)

---

## Visão Geral

O **CRM 3K** é um sistema completo de gestão desenvolvido especificamente para empresas gráficas e cybercafés. O sistema integra todas as operações comerciais, desde a prospecção de clientes até a faturação final.

### Principais Características

- ✅ **Multi-Tenancy**: Suporta múltiplas empresas isoladas na mesma instalação
- ✅ **CRM Completo**: Gestão de leads, oportunidades e pipeline de vendas
- ✅ **Gestão Gráfica**: Orçamentos, trabalhos e produção
- ✅ **Cyber Café**: Controlo de máquinas e sessões
- ✅ **Faturação**: Gestão completa de faturas e pagamentos
- ✅ **Tarefas**: Sistema de gestão de tarefas vinculadas a qualquer entidade
- ✅ **Produtos**: Catálogo com preços e regras de desconto por quantidade

---

## Arquitetura do Sistema

### Stack Tecnológico

- **Backend**: Ruby on Rails 7.1.6
- **Database**: PostgreSQL
- **Frontend**: Turbo Rails + Stimulus + Bootstrap 5.3
- **Autenticação**: Devise
- **Multi-tenancy**: acts_as_tenant (row-level isolation)

### Estrutura Multi-Tenant

```
┌─────────────────────────────────────┐
│         CRM 3K Platform             │
├─────────────────────────────────────┤
│  Tenant 1          Tenant 2         │
│  ┌──────────┐    ┌──────────┐      │
│  │ Users    │    │ Users    │      │
│  │ Customers│    │ Customers│      │
│  │ Jobs     │    │ Jobs     │      │
│  │ ...      │    │ ...      │      │
│  └──────────┘    └──────────┘      │
│  (Isolado)       (Isolado)         │
└─────────────────────────────────────┘
```

Cada tenant (empresa) tem seus dados completamente isolados dos demais através da coluna `tenant_id` em todas as tabelas.

---

## Módulos do Sistema

### 1. Dashboard (Painel)

**Rota**: `/dashboard`

O painel principal exibe:
- **Cards de Estatísticas**:
  - Total de clientes
  - Trabalhos ativos
  - Faturas pendentes
- **Receita do Dia**: Total de pagamentos + sessões de cybercafé
- **Ações Rápidas**: Links para criar novos registos
- **Atividades Recentes**:
  - Trabalhos recentes (últimos 5)
  - Tarefas pendentes ordenadas por data

### 2. CRM (Gestão Comercial)

#### 2.1. Leads
**Rota**: `/leads`

Gestão de prospectos antes de se tornarem clientes.

**Campos**:
- Nome, empresa, email, telefone
- Fonte (web, telefone, referência, etc.)
- Classificação: Hot 🔥 / Warm 🌡️ / Cold ❄️
- Responsável (utilizador)
- Notas

**Funcionalidades**:
- Criar, editar, visualizar, eliminar leads
- **Conversão para Cliente**: Transforma automaticamente em cliente
- Filtros por classificação e estado (convertido/não convertido)

#### 2.2. Oportunidades
**Rota**: `/opportunities`

Pipeline de vendas com gestão visual.

**Campos**:
- Título, descrição
- Cliente (obrigatório)
- Lead de origem (opcional)
- Valor, probabilidade (0-100%)
- Data prevista de fecho
- Responsável e criador

**Estágios do Pipeline**:
1. **Novo** - Oportunidade identificada
2. **Qualificado** - Cliente com interesse real
3. **Proposta** - Proposta comercial enviada
4. **Negociação** - Em discussão de valores/condições
5. **Ganho** ✅ - Oportunidade fechada com sucesso
6. **Perdido** ❌ - Oportunidade não concretizada

**Funcionalidades**:
- Vista de Lista e **Vista Kanban** com drag & drop
- Marcar como ganha/perdida (com motivo)
- **Conversão para Orçamento**
- Cálculo de valor ponderado (valor × probabilidade)
- Estatísticas por fase

### 3. Clientes
**Rota**: `/customers`

Gestão de clientes particulares e empresas.

**Campos**:
- Nome, tipo (particular/empresa)
- NIF (empresas)
- Email, telefone, WhatsApp
- Morada, cidade
- Notas

**Funcionalidades**:
- CRUD completo
- Visualização de histórico (orçamentos, trabalhos, faturas)

### 4. Produtos
**Rota**: `/products`

Catálogo de produtos e serviços.

**Campos**:
- Nome, categoria (gráfica/lanhouse)
- Preço base, unidade
- Estado (ativo/inativo)

**Regras de Preço**:
- Descontos por quantidade
- Exemplo: 100 un = -10%, 500 un = -20%

### 5. Gráfica

#### 5.1. Orçamentos
**Rota**: `/estimates`

Sistema de orçamentos com workflow de aprovação.

**Estados**:
1. **Rascunho** - Em edição
2. **Pendente** - Aguardando aprovação
3. **Aprovado** ✅ - Aprovado, pode gerar trabalho
4. **Recusado** ❌ - Rejeitado

**Funcionalidades**:
- Adicionar itens (produto, quantidade, preço, desconto)
- Submeter para aprovação
- Aprovar/Recusar (gerentes)
- **Converter para Trabalho** (se aprovado)
- Geração de PDF

#### 5.2. Trabalhos (Jobs)
**Rota**: `/jobs`

Gestão de trabalhos de produção.

**Estados**:
- Pendente → Em Produção → Aguardando Revisão → Em Revisão → Completado

**Funcionalidades**:
- Gestão de itens de produção
- Upload de ficheiros (artes, provas)
- Atualização de estado
- Prazo de entrega
- Notas de produção

### 6. Cyber Café

#### 6.1. Máquinas
**Rota**: `/lan_machines`

Gestão de computadores do cybercafé.

**Campos**:
- Nome (PC-01, PC-02...)
- Estado: Livre / Ocupada / Manutenção
- Preço por hora
- Notas

#### 6.2. Sessões
**Rota**: `/lan_sessions`

Controlo de tempo de uso das máquinas.

**Campos**:
- Máquina
- Cliente
- Hora início/fim
- Valor total (calculado automaticamente)

**Funcionalidades**:
- Iniciar sessão
- Fechar sessão (calcula valor automaticamente)
- Histórico de sessões

### 7. Faturas
**Rota**: `/invoices`

Gestão financeira e faturação.

**Estados**:
- Pendente / Paga / Cancelada / Vencida

**Funcionalidades**:
- Criar faturas com múltiplos itens
- Registar pagamentos parciais ou totais
- Cálculo automático de impostos
- Controlo de vencimento

### 8. Tarefas
**Rota**: `/tasks`

Sistema de gestão de tarefas.

**Campos**:
- Título, descrição
- Prioridade (baixa, média, alta)
- Estado (pendente, em progresso, completa)
- Data de vencimento
- Responsável

**Relacionamento Polimórfico**:
As tarefas podem ser vinculadas a:
- Clientes
- Orçamentos
- Trabalhos
- Oportunidades
- Qualquer outra entidade

---

## Workflows Principais

### Workflow 1: Lead → Cliente → Oportunidade → Orçamento → Trabalho → Fatura

```
┌──────────┐
│   LEAD   │  (Prospect identificado)
└────┬─────┘
     │ Conversão
     ▼
┌──────────┐
│ CLIENTE  │  (Cliente registado)
└────┬─────┘
     │ Criar
     ▼
┌─────────────┐
│ OPORTUNIDADE│  (Pipeline de vendas)
└────┬────────┘
     │ Marcar como "Ganho" + Converter
     ▼
┌──────────┐
│ ORÇAMENTO│  (Proposta comercial)
└────┬─────┘
     │ Estado: Rascunho → Pendente
     │ Aprovação ✅
     ▼
┌──────────┐
│ TRABALHO │  (Produção)
└────┬─────┘
     │ Estados: Pendente → Produção → Completado
     ▼
┌──────────┐
│  FATURA  │  (Cobrança)
└────┬─────┘
     │ Registar Pagamento
     ▼
   [Pago ✅]
```

### Workflow 2: Cybercafé

```
┌──────────┐
│ MÁQUINA  │  Estado: Livre
└────┬─────┘
     │ Cliente chega
     ▼
┌──────────────┐
│ INICIAR      │
│ SESSÃO       │  (Registar hora início)
└────┬─────────┘
     │ Cliente usa
     ▼
┌──────────────┐
│ FECHAR       │
│ SESSÃO       │  (Calcular tempo × valor/hora)
└────┬─────────┘
     │ Cobrar
     ▼
┌──────────┐
│  FATURA  │  ou Recibo
└──────────┘
```

### Workflow 3: Gestão de Oportunidades (Kanban)

```
Pipeline Visual:
┌──────┐  ┌──────────┐  ┌─────────┐  ┌───────────┐
│ Novo │→ │Qualificado│→ │Proposta │→ │Negociação │
└──────┘  └──────────┘  └─────────┘  └───────────┘
                                            ↓
                                    ┌───────┴───────┐
                                    │               │
                                    ▼               ▼
                                ┌──────┐       ┌────────┐
                                │Ganho │       │Perdido │
                                └──────┘       └────────┘
                                    ↓
                            Converter para Orçamento
```

**Drag & Drop**: Arraste cards entre colunas para atualizar o estágio automaticamente.

### Workflow 4: Aprovação de Orçamentos

```
Utilizador cria orçamento
        ↓
[Estado: Rascunho]
        ↓
Adiciona itens + valores
        ↓
Submete para aprovação
        ↓
[Estado: Pendente]
        ↓
    Gerente revê
        ↓
   ┌────┴────┐
   ▼         ▼
Aprovar   Recusar
   │         │
   ▼         ▼
[Aprovado] [Recusado]
   │
   ▼
Converter para Trabalho
   ↓
[Trabalho criado]
```

---

## Perfis de Utilizador

### 1. Admin (Administrador)
**Permissões**: Acesso total ao sistema
- Gestão de utilizadores
- Configurações do tenant
- Acesso a todos os módulos

### 2. Atendente
**Permissões**: Front office
- Gestão de clientes
- Criação de orçamentos
- Gestão de sessões de cybercafé
- Visualização de trabalhos

### 3. Produção
**Permissões**: Back office
- Visualização de orçamentos
- Gestão completa de trabalhos
- Upload de ficheiros de produção
- Atualização de estados

### 4. Financeiro
**Permissões**: Área financeira
- Visualização de orçamentos e trabalhos
- Gestão completa de faturas
- Registar pagamentos
- Relatórios financeiros

### Super Admin
**Acesso especial**: Gestão multi-tenant
- Visualizar e gerir todos os tenants
- Renovar subscrições
- Acesso ao Admin Panel (`/admin/tenants`)

---

## Funcionalidades Detalhadas

### Multi-Tenancy

Cada empresa (tenant) possui:
- **Dados isolados**: Nenhum tenant vê dados de outro
- **Subscrição**: Data de início e fim
- **Configurações**: Logo, cores, impostos, moeda
- **Utilizadores próprios**: Com roles específicos

**Bloqueio Automático**: Se a subscrição expirar, o acesso é bloqueado automaticamente.

### Conversões Automáticas

#### Lead → Cliente
- Cria automaticamente registo de cliente
- Mantém referência ao lead original
- Copia nome, email, telefone
- Define tipo como "particular"

#### Oportunidade → Orçamento
- Só disponível para oportunidades abertas
- Cria orçamento vinculado ao cliente
- Estado inicial: "pending"
- Marca oportunidade como "ganha"

#### Orçamento → Trabalho
- Só se orçamento estiver aprovado
- Copia todos os itens do orçamento
- Define cliente e utilizador responsável
- Estado inicial: "pending"

### Sistema Kanban

**Funcionalidades**:
- Visualização em colunas por estágio
- Drag & drop entre estágios
- Atualização AJAX em tempo real
- Indicadores por coluna:
  - Contagem de oportunidades
  - Valor total em euros
- Recarga automática após mudança

### Cálculos Automáticos

#### Orçamentos e Trabalhos
```ruby
Total Item = Quantidade × Preço Unitário × (1 - Desconto%)
Subtotal = Soma(Total de todos os itens)
Imposto = Subtotal × Taxa de Imposto
Total = Subtotal + Imposto
```

#### Sessões de Cybercafé
```ruby
Duração = Hora Fim - Hora Início (em horas)
Valor Total = Duração × Preço por Hora da Máquina
```

#### Oportunidades (Valor Ponderado)
```ruby
Valor Ponderado = Valor × (Probabilidade / 100)
```

---

## Acesso ao Sistema

### URL
```
http://localhost:3000
```

### Credenciais Padrão

**Administrador**:
- Email: `admin@3k.com`
- Senha: `password123`

**Outros Utilizadores**:
- Atendente: `atendente@3k.com` / `password123`
- Produção: `producao@3k.com` / `password123`
- Financeiro: `financeiro@3k.com` / `password123`

### Estrutura do Menu

```
┌─ Painel (Dashboard)
├─ CRM
│  ├─ Leads
│  └─ Oportunidades
├─ Clientes
├─ Produtos
├─ Gráfica
│  ├─ Orçamentos
│  └─ Trabalhos
├─ Cyber Café
│  ├─ Máquinas
│  └─ Sessões
├─ Faturas
└─ Tarefas
```

---

## Tecnologias e Padrões

### Backend
- **Ruby on Rails 7.1.6**
- **PostgreSQL**: Base de dados relacional
- **Devise**: Autenticação de utilizadores
- **acts_as_tenant**: Isolamento multi-tenant
- **Pundit**: (Preparado para autorização por roles)

### Frontend
- **Turbo Rails**: SPA-like navigation
- **Stimulus**: JavaScript framework minimalista
- **Bootstrap 5.3**: Framework CSS responsivo
- **Bootstrap Icons**: Iconografia

### Arquitetura
- **MVC Pattern**: Model-View-Controller
- **RESTful API**: Rotas seguem padrão REST
- **Active Record**: ORM do Rails
- **Enums**: Para estados e tipos (stage, status, classification)
- **Scopes**: Queries reutilizáveis
- **Concerns**: Código compartilhado (TenantScoped)

---

## Fluxo de Dados

```
┌──────────────────────────────────────────────────┐
│              Utilizador (Browser)                │
└──────────────┬───────────────────────────────────┘
               │ HTTP Request
               ▼
┌──────────────────────────────────────────────────┐
│         Rails Router (config/routes.rb)          │
└──────────────┬───────────────────────────────────┘
               │ Route Match
               ▼
┌──────────────────────────────────────────────────┐
│         Controller (app/controllers/)            │
│  - Autenticação (Devise)                         │
│  - Set Current Tenant (acts_as_tenant)           │
│  - Business Logic                                │
└──────────────┬───────────────────────────────────┘
               │ Query Database
               ▼
┌──────────────────────────────────────────────────┐
│         Models (app/models/)                     │
│  - Active Record                                 │
│  - Validations                                   │
│  - Associations                                  │
│  - Scopes (scoped by tenant_id)                 │
└──────────────┬───────────────────────────────────┘
               │ Data
               ▼
┌──────────────────────────────────────────────────┐
│         Views (app/views/)                       │
│  - ERB Templates                                 │
│  - Partials                                      │
│  - Helpers                                       │
└──────────────┬───────────────────────────────────┘
               │ HTML + Turbo
               ▼
┌──────────────────────────────────────────────────┐
│         Browser (Client)                         │
│  - Bootstrap CSS                                 │
│  - Stimulus JS (Kanban drag & drop)             │
└──────────────────────────────────────────────────┘
```

---

## Próximos Passos (Roadmap)

Funcionalidades planejadas conforme o plano original:

### Sprint 5: Contatos e Comunicação
- Múltiplos contatos por cliente
- Registo de comunicações (emails, chamadas, reuniões)
- Timeline unificado de atividades

### Sprint 6: Roles e Permissões
- Roles configuráveis por tenant
- Permissões granulares por módulo
- Policies com Pundit

### Sprint 7: Relatórios Avançados
- Dashboard com gráficos (Chart.js)
- Relatórios por período
- KPIs por utilizador
- Export CSV/PDF

---

## Suporte e Manutenção

### Logs
```bash
# Ver logs do servidor
tail -f log/development.log

# Ver logs de produção
tail -f log/production.log
```

### Console Rails
```bash
# Abrir console
bin/rails console

# Verificar tenant
ActsAsTenant.current_tenant

# Queries de teste
Customer.count
Opportunity.open.count
```

### Backup
```bash
# Backup da base de dados
pg_dump -U postgres crm_3k_development > backup.sql

# Restaurar
psql -U postgres crm_3k_development < backup.sql
```

---

## Glossário

- **Tenant**: Empresa/organização que usa o sistema (multi-tenancy)
- **Lead**: Prospect, potencial cliente
- **Oportunidade**: Negócio em potencial no pipeline de vendas
- **Pipeline**: Funil de vendas com múltiplas fases
- **Kanban**: Quadro visual para gestão de processos
- **Drag & Drop**: Arrastar e soltar (funcionalidade do Kanban)
- **Workflow**: Fluxo de trabalho definido
- **CRUD**: Create, Read, Update, Delete (operações básicas)
- **Scope**: Filtro reutilizável em queries
- **Enum**: Tipo enumerado (lista fixa de valores)
- **Polimórfico**: Relacionamento que pode apontar para múltiplos modelos

---

## Contato e Documentação Adicional

Para mais informações:
- **README.md**: Instruções de instalação e setup
- **db/schema.rb**: Estrutura completa da base de dados
- **config/routes.rb**: Todas as rotas disponíveis

---

**Versão**: 1.0
**Última Atualização**: Dezembro 2025
**Desenvolvido com**: Ruby on Rails 7.1.6 + PostgreSQL + Bootstrap 5.3
