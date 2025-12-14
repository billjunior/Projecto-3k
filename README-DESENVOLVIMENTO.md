# CRM 3K - Sistema de Gestão para Gráfica e CyberCafé

Sistema CRM completo desenvolvido em Ruby on Rails para gestão de uma gráfica e cybercafé.

## Stack Tecnológico

- **Ruby**: 3.0.0
- **Rails**: 7.1.3.4
- **PostgreSQL**: Base de dados
- **Devise**: Autenticação de usuários
- **Pundit**: Autorização (a implementar)
- **Bootstrap**: Interface responsiva
- **Kaminari**: Paginação

## Estrutura do Projeto

### Models Criados (15 tabelas)

1. **User** - Usuários do sistema com 4 roles (admin, atendente, producao, financeiro)
2. **Customer** - Clientes (particulares e empresas)
3. **Product** - Produtos e serviços (gráfica e lanhouse)
4. **PriceRule** - Regras de preço por quantidade
5. **Estimate** - Orçamentos com itens
6. **EstimateItem** - Itens dos orçamentos
7. **Job** - Trabalhos da gráfica
8. **JobItem** - Itens dos trabalhos
9. **JobFile** - Arquivos anexos aos trabalhos
10. **LanMachine** - Computadores do cybercafé
11. **LanSession** - Sessões de uso dos computadores
12. **Invoice** - Faturas e recibos
13. **InvoiceItem** - Itens das faturas
14. **Payment** - Pagamentos
15. **Task** - Tarefas e lembretes

### Funcionalidades Implementadas

#### Autenticação (Devise)
- Login/Logout de usuários
- Gestão de passwords
- 4 perfis de usuário com diferentes permissões

#### Models com Lógica de Negócio
- **Estimate**: Conversão automática para Job
- **Job**: Gestão de estados de produção, cálculo de saldos
- **LanSession**: Cronometragem automática, cálculo de valores
- **Invoice**: Cálculo automático de status (pago/parcial/pendente)
- **Product**: Preços dinâmicos por quantidade

## Como Iniciar o Desenvolvimento

### 1. Servidor de Desenvolvimento

```bash
cd crm_3k
rails server
```

Acesse: http://localhost:3000

### 2. Credenciais de Acesso

**Administrador:**
- Email: admin@3k.com
- Senha: password123

**Outros usuários:**
- Atendente: atendente@3k.com / password123
- Produção: producao@3k.com / password123
- Financeiro: financeiro@3k.com / password123

### 3. Dados de Exemplo

O banco já foi populado com:
- 4 usuários (1 de cada perfil)
- 8 clientes (5 particulares, 3 empresas)
- 9 produtos (5 gráfica, 4 lanhouse)
- 10 máquinas do cybercafé

## Próximos Passos

### Controllers e Views a Criar

1. **Dashboard** (em andamento)
   - Resumo de vendas do dia
   - Trabalhos em produção
   - Máquinas ocupadas
   - Tarefas pendentes

2. **Customers Controller**
   - CRUD completo
   - Histórico de trabalhos e sessões
   - Relatório por cliente

3. **Products Controller**
   - CRUD completo
   - Gestão de regras de preço
   - Categorização

4. **Estimates Controller**
   - CRUD com formulário de itens dinâmico
   - Aprovação/Rejeição
   - Conversão para trabalho
   - PDF do orçamento

5. **Jobs Controller**
   - CRUD completo
   - Painel de produção por estado
   - Upload de arquivos
   - Atualização de status
   - Timeline de produção

6. **LanMachines & LanSessions Controllers**
   - Painel de máquinas (grid visual)
   - Iniciar/Fechar sessões
   - Cronômetro em tempo real
   - Cálculo automático de valores

7. **Invoices Controller**
   - CRUD completo
   - Registro de pagamentos
   - Geração de PDF
   - Controle de dívidas

8. **Tasks Controller**
   - CRUD completo
   - Filtros por status e responsável
   - Calendário de tarefas

### Implementação de Autorização (Pundit)

Definir políticas para cada perfil:

- **Admin**: Acesso total
- **Atendente**: Clientes, orçamentos, trabalhos, sessões LAN, faturas
- **Produção**: Apenas trabalhos (visualizar e atualizar status)
- **Financeiro**: Faturas, pagamentos, relatórios

### Interface com Bootstrap

1. Layout principal com navegação
2. Dashboards personalizados por perfil
3. Formulários com validações client-side
4. Tabelas com paginação (Kaminari)
5. Modais para ações rápidas
6. Toasts para notificações

### Relatórios

1. Vendas por período (dia/semana/mês)
2. Vendas por tipo (gráfica vs lanhouse)
3. Top clientes
4. Trabalhos atrasados
5. Uso de máquinas do cybercafé
6. Análise de dívidas

## Comandos Úteis

```bash
# Console do Rails
rails console

# Rotas
rails routes

# Verificar models
rails db:schema:dump

# Recriar banco
rails db:drop db:create db:migrate db:seed

# Gerar controllers
rails g controller Customers index show new create edit update destroy

# Gerar scaffold (exemplo)
rails g scaffold_controller Customer

# Testes
rails test
```

## Estrutura de Pastas

```
crm_3k/
├── app/
│   ├── controllers/     # Controllers (dashboard criado)
│   ├── models/          # 15 models completos
│   ├── views/           # Views do Devise criadas
│   ├── helpers/
│   └── assets/
├── config/
│   ├── routes.rb        # Rotas principais configuradas
│   └── database.yml
├── db/
│   ├── migrate/         # 15 migrações criadas
│   ├── schema.rb
│   └── seeds.rb         # Seeds completos
└── README-DESENVOLVIMENTO.md
```

## Contribuindo

Para adicionar novas funcionalidades:

1. Criar branch feature
2. Implementar controller + views
3. Adicionar testes
4. Criar pull request

## Suporte

Para dúvidas sobre a especificação, consulte o documento original de requisitos.
