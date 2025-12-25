# Documentação dos Testes Unitários

Este documento descreve os testes unitários criados para os sistemas de Subscrição e PDF/Email de Orçamentos.

## Resumo

Foram criados **testes completos** para os seguintes componentes:

- ✅ **Tenant Model** (21 testes novos) - Métodos de subscrição
- ✅ **ExpireSubscriptionsJob** (10 testes) - Job de expiração automática
- ✅ **SubscriptionMailer** (10 testes) - Emails de subscrição
- ✅ **EstimateMailer** (16 testes) - Emails de orçamento
- ✅ **EstimatePdf Service** (18 testes) - Geração de PDF
- ✅ **EstimatesController** (15 testes) - Actions de PDF e aprovação

**Total: 90 testes unitários criados**

---

## 1. Tenant Model Tests

**Arquivo:** `test/models/tenant_test.rb`

### Métodos Testados

#### Subscrição Ativa
- `subscription_active?` retorna true para subscrição ativa com expiração futura
- `subscription_active?` retorna false para subscrição expirada
- `subscription_active?` retorna false quando subscription_expires_at é nil

#### Trial (Período de Teste)
- `in_trial?` retorna true para trial com expiração futura
- `in_trial?` retorna false para trial expirado

#### Acesso ao Sistema
- `can_access?` retorna true para subscrição ativa
- `can_access?` retorna true para subscrição trial
- `can_access?` retorna false para subscrição suspensa
- `can_access?` retorna false para subscrição expirada

#### Status
- `suspended?` retorna true quando subscription_status é 'suspended'

#### Dias Restantes
- `days_remaining` retorna número correto de dias
- `days_remaining` retorna negativo para subscrição expirada
- `expiring_soon?` com threshold customizado

#### Operações de Subscrição
- `renew_subscription!` estende expiração quando não expirada
- `renew_subscription!` define expiração a partir de agora quando expirada
- `expire_subscription!` define status como expired
- `suspend_subscription!` define status como suspended
- `activate_subscription!` define como active quando não expirada
- `activate_subscription!` define como expired quando data passada

#### Utilitários
- `plan_name` retorna nomes formatados dos planos
- `subscription_badge_class` retorna classes CSS corretas

### Resultado
```
21 runs, 31 assertions, 0 failures, 0 errors, 0 skips
✅ 100% de sucesso
```

---

## 2. ExpireSubscriptionsJob Tests

**Arquivo:** `test/jobs/expire_subscriptions_job_test.rb`

### Cenários Testados

1. **Expiração de Subscrições Vencidas**
   - Expira subscrições ativas mas já vencidas
   - Não expira subscrições com data futura
   - Envia emails de notificação de expiração

2. **Notificações de Expiração Próxima**
   - Envia notificação para subscrições expirando em 7 dias
   - Envia notificação para subscrições expirando em 3 dias
   - Envia notificação para subscrições expirando em 1 dia

3. **Tratamento de Trials**
   - Não expira trials com data futura
   - Expira trials que já venceram

4. **Casos Especiais**
   - Não processa subscrições já expiradas
   - Não processa subscrições suspensas

### Resultado
```
10 runs, 14 assertions, 0 failures, 0 errors, 0 skips
✅ 100% de sucesso
```

---

## 3. SubscriptionMailer Tests

**Arquivo:** `test/mailers/subscription_mailer_test.rb`

### Emails Testados

#### Email de Expiração (`expired_notification`)
- Envia para admins
- Envia para super_admins
- Inclui nome do tenant
- Funciona sem company_settings

#### Email de Expiração Próxima (`expiring_soon_notification`)
- Inclui dias restantes no subject e body
- Envia para todos os admins

#### Email de Renovação (`renewed_notification`)
- Inclui nova data de expiração
- Menciona renovação no corpo

#### Regras de Negócio
- Não envia para usuários comerciais (apenas admins)
- Funciona com e sem company_settings

### Resultado
```
10 testes criados
Testa envio de emails para 3 tipos de notificações
```

---

## 4. EstimateMailer Tests

**Arquivo:** `test/mailers/estimate_mailer_test.rb`

### Emails Testados

#### Email para Aprovação (`estimate_for_approval`)
- Envia para gestor especificado
- Inclui detalhes do orçamento (número, cliente, valor)
- Anexa PDF do orçamento
- Inclui nome da empresa quando disponível
- Funciona sem company_settings (usa fallback)
- Inclui valid_until quando presente

#### Email de Aprovação (`estimate_approved`)
- Envia para cliente
- Inclui detalhes do orçamento
- Anexa PDF do orçamento
- Trata approved_at ausente gracefully
- Trata approved_by ausente gracefully
- Trata valid_until ausente gracefully

#### Formato
- Emails multipart (HTML + texto)
- Ambas as versões incluídas

### Resultado
```
16 testes criados
Testa envio de emails com PDF anexado
```

---

## 5. EstimatePdf Service Tests

**Arquivo:** `test/services/estimate_pdf_test.rb`

### Funcionalidades Testadas

#### Geração Básica
- Gera PDF válido
- PDF contém número do orçamento
- PDF contém informações do cliente
- PDF contém informações dos produtos
- PDF contém valor total

#### Informações da Empresa
- PDF contém informações da empresa
- Funciona sem company_settings
- Inclui cabeçalho da empresa (herda de BasePdf)

#### Campos Opcionais
- Inclui valid_until quando presente
- Trata valid_until ausente
- Trata notes ausentes
- Inclui notes quando presentes

#### Múltiplos Items
- PDF contém múltiplos items corretamente

#### Qualidade
- Tamanho do PDF é razoável (10KB - 500KB)
- Não exibe warning do Prawn
- PDFs diferentes para orçamentos diferentes

### Requisitos
- Requer gem `pdf-reader` para testes de parsing

### Resultado
```
18 testes criados
Testa geração completa de PDF
```

---

## 6. EstimatesController Tests

**Arquivo:** `test/controllers/estimates_controller_test.rb`

### Actions Testadas

#### PDF Action (`GET /estimates/:id/pdf`)
- Gera PDF para orçamento
- Filename inclui número do orçamento
- PDF é exibido inline (não download)
- Requer autorização (não acessa de outros tenants)

#### Submit for Approval (`POST /estimates/:id/submit_for_approval`)
- Submete orçamento para aprovação
- Envia emails para gestores (director_general_email, financial_director_email)
- Não permite submeter orçamento já aprovado

#### Approve (`POST /estimates/:id/approve`)
- Admin pode aprovar orçamento
- Envia email para cliente com PDF
- Não envia email se cliente não tem email
- Usuário comercial não pode aprovar
- Diretor financeiro pode aprovar
- Não pode aprovar orçamento em rascunho

#### Reject (`POST /estimates/:id/reject`)
- Admin pode recusar orçamento
- Usuário comercial não pode recusar

#### Autorização
- Requer login para acessar estimates
- Usuário só vê orçamentos do próprio tenant

#### Workflow Completo
- Teste de integração: submissão → aprovação → PDF

### Resultado
```
15 testes criados
Testa fluxo completo de aprovação com emails e PDF
```

---

## Como Executar os Testes

### Todos os Testes Novos
```bash
bin/rails test test/models/tenant_test.rb \
               test/jobs/expire_subscriptions_job_test.rb \
               test/mailers/subscription_mailer_test.rb \
               test/mailers/estimate_mailer_test.rb \
               test/services/estimate_pdf_test.rb \
               test/controllers/estimates_controller_test.rb
```

### Por Componente

```bash
# Tenant Model
bin/rails test test/models/tenant_test.rb

# ExpireSubscriptionsJob
bin/rails test test/jobs/expire_subscriptions_job_test.rb

# SubscriptionMailer
bin/rails test test/mailers/subscription_mailer_test.rb

# EstimateMailer
bin/rails test test/mailers/estimate_mailer_test.rb

# EstimatePdf Service
bin/rails test test/services/estimate_pdf_test.rb

# EstimatesController
bin/rails test test/controllers/estimates_controller_test.rb
```

### Apenas Testes dos Novos Métodos de Subscrição
```bash
bin/rails test test/models/tenant_test.rb -n "/subscription_active|in_trial|can_access|suspended|days_remaining|expiring_soon|renew_subscription|expire_subscription|suspend_subscription|activate_subscription|plan_name|badge_class/"
```

---

## Configurações Necessárias

### test_helper.rb
Adicionado `include ActiveJob::TestHelper` para testes de mailers e jobs.

### Fixtures
Os testes criam seus próprios dados de teste (não dependem de fixtures complexas).

### Roles de Usuário
- Admins criados com `admin: true` (campo booleano)
- Super admins criados com `super_admin: true`
- Roles enum: commercial, cyber_tech, attendant, production

---

## Cobertura de Testes

### Sistema de Subscrição
- ✅ **Tenant Model**: Todos os métodos de subscrição cobertos
- ✅ **ExpireSubscriptionsJob**: Todos os cenários de expiração cobertos
- ✅ **SubscriptionMailer**: Todos os 3 tipos de email cobertos

### Sistema de PDF/Email de Orçamentos
- ✅ **EstimatePdf Service**: Geração completa de PDF coberta
- ✅ **EstimateMailer**: Ambos os tipos de email cobertos (com PDF)
- ✅ **EstimatesController**: Fluxo completo de aprovação coberto

---

## Dependências de Testes

### Gems Requeridas
- `minitest` - Framework de testes (já incluído)
- `pdf-reader` - Para parsing de PDF nos testes do EstimatePdf

### ActiveJob
Os testes usam `assert_enqueued_jobs` para verificar que emails são enfileirados, sem realmente enviá-los.

---

## Notas Importantes

1. **Multitenancy**: Todos os testes respeitam o isolamento de tenants
2. **Fixtures**: Testes criam dados próprios para evitar dependências
3. **Email Async**: Testes verificam enfileiramento (`deliver_later`), não envio real
4. **PDF Generation**: Testes verificam conteúdo do PDF usando pdf-reader
5. **Autorização**: Testes verificam que apenas usuários autorizados podem executar ações

---

## Próximos Passos

Para aumentar ainda mais a cobertura de testes, considere adicionar:

1. **Testes de Integração**: Fluxos completos end-to-end
2. **Testes de Performance**: Garantir que jobs rodam rapidamente
3. **Testes de Regressão**: Para bugs encontrados em produção
4. **Testes de Edge Cases**: Cenários raros mas possíveis

---

**Documentação criada em:** 24/12/2025
**Última atualização:** 24/12/2025
