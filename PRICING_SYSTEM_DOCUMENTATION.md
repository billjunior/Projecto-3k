# Sistema de Precificação Inteligente - Documentação

## Visão Geral

O Sistema de Precificação Inteligente é uma funcionalidade completa que ajuda a manter as margens de lucro desejadas nos orçamentos e faturas, alertando automaticamente quando os preços ficam abaixo da margem esperada ou quando descontos são aplicados.

## Características Principais

### 1. Margem de Lucro Configurável
- Margem de lucro padrão configurável por empresa/tenant
- Valor recomendado: 65%
- Usado para calcular preços sugeridos e identificar problemas

### 2. Gestão de Descontos
- Descontos aplicados a nível de documento (global)
- Justificação obrigatória para qualquer desconto (mínimo 10 caracteres)
- Validação em tempo real durante a digitação
- Cálculo automático do valor total com desconto

### 3. Validação em Tempo Real
- Análise automática de margem enquanto preenche o formulário
- Avisos visuais se preços ficarem abaixo da margem esperada
- Debounce de 800ms para evitar validações excessivas
- Feedback imediato sobre justificação de desconto

### 4. Notificações Automáticas por Email
- Emails automáticos para Diretor Geral e Diretor Financeiro
- Enviados quando margem fica abaixo do esperado
- Incluem análise detalhada e PDF do documento anexado
- Mostram itens específicos com margem baixa

### 5. Relatórios de Análise de Preços
- Dashboard completo com métricas agregadas
- Gráficos de tendências (avisos por dia, perda de lucro)
- Listagem de documentos problemáticos
- Top 10 documentos com maior perda de lucro

## Configuração Inicial

### Passo 1: Configurar Margem de Lucro

1. Acesse **Configurações da Empresa**
2. Localize a seção **Configuração de Precificação Inteligente**
3. Defina a **Margem de Lucro Padrão (%)** (recomendado: 65%)
4. Clique em **Salvar Configurações**

Esta margem será usada para:
- Calcular preços sugeridos
- Identificar preços abaixo do esperado
- Gerar alertas automáticos

### Passo 2: Configurar Emails dos Diretores

1. Na mesma página de **Configurações da Empresa**
2. Localize a seção **Emails para Notificações de Itens em Falta**
3. Preencha:
   - **Email do Director Geral**
   - **Email da Directora Financeira**
4. Estes emails receberão alertas de margem baixa

## Como Usar

### Criar Orçamento ou Fatura com Desconto

1. **Criar Novo Documento**
   - Acesse **Orçamentos** → **Novo Orçamento** (ou **Faturas** → **Nova Fatura**)
   - Preencha cliente e itens normalmente

2. **Aplicar Desconto (Opcional)**
   - Na seção **Desconto**, insira a percentagem de desconto
   - **IMPORTANTE:** Campo de justificação torna-se obrigatório
   - Digite justificação com mínimo 10 caracteres
   - Exemplos de justificações válidas:
     - "Cliente fidelizado há 5 anos, desconto de fidelidade"
     - "Campanha promocional de fim de ano"
     - "Grande volume de compra, desconto negociado"

3. **Validação em Tempo Real**
   - Enquanto preenche, o sistema analisa automaticamente
   - Se margem ficar abaixo do esperado, aparece aviso laranja:
     ```
     ⚠️ Avisos de Preço:
     • Margem Abaixo do Esperado: Esperado 65%, Real 45%
     • Produto XYZ: Margem 40% (abaixo de 65%)
     ```

4. **Salvar Documento**
   - Ao clicar em **Guardar**, sistema realiza validação final
   - Se margem baixa detectada:
     - Email automático enviado aos diretores
     - Aviso registrado no sistema
     - Documento salvo normalmente

### Visualizar Análise de Preços (Apenas Diretores)

Quando diretores ou diretor financeiro visualizam um orçamento/fatura, vêem seção adicional:

**📊 Análise de Preços (Diretores)**
- Margem Esperada vs Margem Real
- Custo Total e Lucro Real
- Desconto Aplicado (se houver)
- Justificação do Desconto
- Lista de itens abaixo da margem
- Perda estimada de lucro

## Relatório de Análise de Preços

### Acesso
**Relatórios** → **Análise de Preços**

### Funcionalidades

1. **Filtros de Data**
   - Data Início / Data Fim
   - Padrão: mês atual

2. **Métricas de Resumo**
   - Total de Avisos
   - Perda Total de Lucro (AOA)
   - Défice Médio de Margem (%)
   - Total de Descontos (AOA)

3. **Gráficos**
   - Avisos por Dia (linha)
   - Avisos por Tipo (pizza): Margem Baixa vs Desconto Alto
   - Perda de Lucro por Dia (área)

4. **Top 10 Documentos**
   - Documentos com maior perda de lucro
   - Inclui: tipo, número, cliente, margens, perda

5. **Listagem Completa**
   - Orçamentos com problemas (paginado)
   - Faturas com problemas (paginado)
   - Filtros e status de margem

## Estrutura de Dados

### CompanySetting
```ruby
default_profit_margin: decimal(5,2)  # Margem padrão (ex: 65.00)
```

### Estimate / Invoice
```ruby
discount_percentage: decimal(5,2)          # Ex: 10.50%
discount_amount: decimal(10,2)             # Valor calculado
discount_justification: text               # Mínimo 10 caracteres
subtotal_before_discount: decimal(10,2)    # Subtotal antes do desconto
below_margin_warned: boolean               # Flag de aviso enviado
below_margin_warned_at: datetime           # Timestamp do aviso
```

### PricingWarning
```ruby
tenant_id: integer
warnable_id/type: polymorphic (Estimate ou Invoice)
created_by_user_id: integer
warning_type: string               # 'below_margin' ou 'high_discount'
expected_margin: decimal(5,2)      # Margem esperada
actual_margin: decimal(5,2)        # Margem real
margin_deficit: decimal(5,2)       # Défice
profit_loss: decimal(10,2)         # Perda de lucro estimada
item_breakdown: jsonb              # Detalhes dos itens
justification: text                # Cópia da justificação
director_notified: boolean         # Email enviado?
director_notified_at: datetime     # Timestamp do email
```

## Lógica de Cálculo

### Cálculo de Margem
```ruby
# Para cada item:
unit_cost = labor_cost + material_cost + purchase_price
item_margin = ((unit_price - unit_cost) / unit_cost) * 100

# Para documento completo:
total_cost = soma de (unit_cost * quantity) para todos os itens
total_revenue = total_value (após desconto)
total_profit = total_revenue - total_cost
actual_margin = (total_profit / total_cost) * 100
```

### Cálculo de Perda
```ruby
expected_profit = total_cost * (expected_margin / 100)
profit_loss = expected_profit - total_profit
margin_deficit = expected_margin - actual_margin
```

### Aplicação de Desconto
```ruby
subtotal_before_discount = soma de (quantity * unit_price)
discount_amount = subtotal_before_discount * (discount_percentage / 100)
total_value = subtotal_before_discount - discount_amount
```

## Fluxo de Notificações

1. **Criação/Atualização de Documento**
   - Usuário salva orçamento/fatura
   - Sistema calcula totais com desconto
   - Validação de justificação (se desconto > 0)

2. **Análise de Preços**
   - `PricingAnalyzer` analisa margem de cada item
   - Identifica itens abaixo da margem esperada
   - Calcula défice total e perda de lucro

3. **Notificação (se necessário)**
   - `PricingNotifier` verifica se há avisos
   - Se `below_margin_warned == false`:
     - Cria `PricingWarning` no banco
     - Gera PDF do documento
     - Envia email para diretores com PDF anexado
     - Marca documento como `below_margin_warned = true`

4. **Email Enviado**
   - **Assunto:** ⚠️ ALERTA: Preço Abaixo da Margem - [Tipo] [Número]
   - **Para:** Director Geral + Directora Financeira
   - **Conteúdo:**
     - Informações do documento
     - Análise de margem (esperada vs real)
     - Itens abaixo da margem
     - Justificação do desconto (se houver)
     - Link para visualizar documento
   - **Anexo:** PDF do documento

## Permissões (Pundit)

### Aplicar Descontos
```ruby
apply_discount?
  -> super_admin, admin, commercial
```

### Visualizar Análise de Preços
```ruby
view_pricing_analysis?
  -> super_admin, admin, financeiro (diretor financeiro)
```

### Validar Preços (AJAX)
```ruby
validate_pricing?
  -> Qualquer usuário que possa criar/editar documentos
```

## API Endpoints

### Validação de Preços (AJAX)
```
POST /estimates/validate_pricing
POST /invoices/validate_pricing

Body:
{
  "estimate": {
    "customer_id": 123,
    "discount_percentage": 10,
    "discount_justification": "Cliente fidelizado",
    "estimate_items_attributes": [
      {
        "product_id": 456,
        "quantity": 2,
        "unit_price": 5000
      }
    ]
  }
}

Response:
{
  "valid": false,
  "analysis": {
    "expected_margin": 65.0,
    "actual_margin_percentage": 45.23,
    "margin_deficit": 19.77,
    "below_margin_items": [
      {
        "product_name": "Produto XYZ",
        "margin_percentage": 40.0,
        "profit_loss": 1250.50
      }
    ],
    "severity": "high"
  }
}
```

## Troubleshooting

### Emails Não São Enviados

**Problema:** Diretores não recebem emails de alerta

**Soluções:**
1. Verificar que emails estão configurados em **Configurações da Empresa**
2. Verificar logs do servidor: `tail -f log/production.log | grep PricingMailer`
3. Verificar fila de jobs: `rails jobs:workoff` (se usar delayed_job)
4. Testar envio manual no console:
   ```ruby
   estimate = Estimate.last
   warning = estimate.pricing_warnings.last
   PricingMailer.below_margin_alert(estimate, warning, "teste@email.com").deliver_now
   ```

### Validação em Tempo Real Não Funciona

**Problema:** Avisos não aparecem ao digitar

**Soluções:**
1. Verificar console do navegador (F12) para erros JavaScript
2. Verificar se Stimulus controller está carregado:
   ```javascript
   console.log(document.querySelector('[data-controller="pricing-validator"]'))
   ```
3. Verificar CSRF token:
   ```javascript
   console.log(document.querySelector('[name="csrf-token"]').content)
   ```
4. Testar endpoint manualmente com curl/Postman

### Margem Calculada Incorretamente

**Problema:** Margem mostrada não corresponde aos valores esperados

**Soluções:**
1. Verificar que produtos têm custos configurados:
   - `labor_cost`, `material_cost`, `purchase_price`
2. Testar cálculo no console Rails:
   ```ruby
   estimate = Estimate.find(123)
   analyzer = PricingAnalyzer.new(estimate)
   analyzer.analyze
   ```
3. Verificar que `total_value` está correto após desconto
4. Verificar logs de validação em `app/models/estimate.rb:calculate_totals_with_discount`

## Manutenção

### Limpar Avisos Antigos
```ruby
# Remover avisos com mais de 6 meses
PricingWarning.where('created_at < ?', 6.months.ago).delete_all
```

### Reprocessar Avisos
```ruby
# Se precisar reenviar notificações
Estimate.where(below_margin_warned: true).update_all(below_margin_warned: false)

# Então recriar documentos para triggerar notificações
```

### Estatísticas do Sistema
```ruby
# Total de documentos com desconto
Estimate.where('discount_percentage > 0').count
Invoice.where('discount_percentage > 0').count

# Perda total de lucro no mês
PricingWarning.where('created_at >= ?', Date.today.beginning_of_month).sum(:profit_loss)

# Média de desconto aplicado
Estimate.where('discount_percentage > 0').average(:discount_percentage)
```

## Melhorias Futuras

### Sugestões para Próximas Versões

1. **Preço Sugerido Automático**
   - Ao selecionar produto, calcular e sugerir preço automaticamente
   - Baseado em custos + margem configurada

2. **Histórico de Descontos por Cliente**
   - Dashboard mostrando descontos frequentes por cliente
   - Identificar clientes com negociações especiais

3. **Alertas Preventivos**
   - Aviso ANTES de salvar se margem muito baixa
   - Requerer aprovação de diretor para descontos > X%

4. **Análise de Tendências**
   - Gráfico de evolução de margem ao longo do tempo
   - Comparação de margem por vendedor/comercial

5. **Exportação de Relatórios**
   - PDF/Excel do relatório de análise de preços
   - Agendamento de relatórios mensais automáticos

6. **Integração com Dashboard Principal**
   - Widget mostrando perda de lucro do mês
   - Alerta visual para documentos pendentes de revisão

## Suporte

Para questões técnicas ou problemas:
1. Verificar esta documentação
2. Consultar logs do sistema
3. Testar no console Rails
4. Contactar equipa de desenvolvimento

## Changelog

### Versão 1.0 (Dezembro 2024)
- ✅ Margem de lucro configurável por tenant
- ✅ Descontos com justificação obrigatória
- ✅ Validação em tempo real (AJAX)
- ✅ Notificações automáticas por email
- ✅ Relatório completo de análise de preços
- ✅ Políticas de acesso (Pundit)
- ✅ Análise detalhada em show pages (apenas diretores)
