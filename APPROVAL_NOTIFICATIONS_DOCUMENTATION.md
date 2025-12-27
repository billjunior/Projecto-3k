# Sistema de Notificações de Aprovação de Orçamentos

## Visão Geral

Quando um orçamento é aprovado, o sistema envia automaticamente notificações multi-canal para o Director Geral e a Directora Financeira através de:

1. **Email** - Notificação completa com PDF do orçamento em anexo
2. **WhatsApp** - Mensagem formatada com detalhes do orçamento
3. **SMS** - Mensagem resumida com informações essenciais

## Configuração

### Passo 1: Configurar Contactos dos Directores

Aceda a **Configurações da Empresa** e preencha:

#### Director Geral:
- **Email** - Para notificações por email e alertas de itens em falta
- **Telefone** - Para notificações por SMS quando orçamentos forem aprovados
- **WhatsApp** - Para notificações por WhatsApp quando orçamentos forem aprovados

#### Directora Financeira:
- **Email** - Para notificações por email e alertas de itens em falta
- **Telefone** - Para notificações por SMS quando orçamentos forem aprovados
- **WhatsApp** - Para notificações por WhatsApp quando orçamentos forem aprovados

**Nota:** O formato do número de telefone/WhatsApp deve incluir o código do país (ex: +244 XXX XXX XXX)

### Passo 2: Aprovar um Orçamento

Quando um gestor (Admin ou Financeiro) aprova um orçamento:

1. O orçamento muda para status "Aprovado"
2. O cliente recebe um email com o orçamento aprovado (se tiver email cadastrado)
3. Os directores recebem notificações através dos canais configurados

## Como Funciona

### Fluxo de Aprovação

```
Gestor aprova orçamento
         ↓
EstimatesController#approve
         ↓
EstimateApprovalNotifier.notify_directors
         ↓
    ┌────────────┬────────────┬────────────┐
    ↓            ↓            ↓            ↓
  Email      WhatsApp       SMS        Cliente
 (Email)   (WhatsApp)    (Telefone)   (Email)
```

### Canais de Notificação

#### 1. Email
- **Enviado para:** Email configurado do director
- **Conteúdo:**
  - Informações completas do orçamento
  - Detalhes do cliente
  - Valor total e descontos
  - PDF do orçamento em anexo
  - Link para visualizar no sistema
- **Status:** ✅ Implementado e funcional

#### 2. WhatsApp
- **Enviado para:** WhatsApp configurado do director
- **Conteúdo:**
  - Número do orçamento
  - Nome do cliente
  - Valor total
  - Data e hora de aprovação
  - Quem aprovou
  - Link para visualizar
- **Formato:** Mensagem formatada com emojis
- **Status:** ⚠️ Implementado parcialmente
  - Links do WhatsApp são gerados e logados
  - Para envio automático, integrar com WhatsApp Business API
  - Atualmente requer integração manual via logs

#### 3. SMS
- **Enviado para:** Telefone configurado do director
- **Conteúdo:** Mensagem resumida com informações essenciais
- **Status:** ⚠️ Implementado parcialmente
  - Mensagens são geradas e logadas
  - Para envio automático, integrar com serviço de SMS (Twilio, Nexmo, etc.)
  - Atualmente requer integração manual via logs

## Logs e Monitoramento

Todas as notificações são registadas nos logs da aplicação:

```ruby
Rails.logger.info "Email de aprovação enviado para Director Geral: director@empresa.com"
Rails.logger.info "WhatsApp para Director Geral: https://wa.me/244XXXXXXXXX?text=..."
Rails.logger.info "SMS para Directora Financeira (244XXXXXXXXX): ORÇAMENTO APROVADO..."
```

### Estrutura de Log JSON

```json
{
  "event": "pending_notification",
  "notification_type": "whatsapp",
  "estimate_id": 123,
  "estimate_number": "EST-20251227-ABC123",
  "recipient": "+244 XXX XXX XXX",
  "recipient_name": "Director Geral",
  "message": "🎉 ORÇAMENTO APROVADO...",
  "url": "https://wa.me/244XXXXXXXXX?text=...",
  "timestamp": "2025-12-27T21:00:00Z"
}
```

## Integração Futura

### WhatsApp Business API

Para envio automático de mensagens WhatsApp:

```ruby
# app/services/estimate_approval_notifier.rb

def send_whatsapp_notification(whatsapp, recipient_name)
  # Integração com WhatsApp Business API
  WhatsappApiClient.send_message(
    to: whatsapp,
    message: whatsapp_message
  )
end
```

**Providers recomendados:**
- Twilio WhatsApp Business API
- MessageBird
- 360dialog
- Meta Cloud API (oficial)

### SMS Gateway

Para envio automático de SMS:

```ruby
# app/services/estimate_approval_notifier.rb

def send_sms_notification(phone, recipient_name)
  # Integração com serviço de SMS
  SmsGateway.send(
    to: phone,
    message: sms_message
  )
end
```

**Providers recomendados:**
- Twilio
- Nexmo (Vonage)
- AWS SNS
- Africa's Talking (específico para África)

## Testes

### Testar Aprovação de Orçamento

1. Crie um orçamento de teste
2. Configure os contactos dos directores
3. Aprove o orçamento como gestor
4. Verifique:
   - Emails enviados (caixa de entrada dos directores)
   - Logs da aplicação (WhatsApp e SMS)
   - Mensagem de sucesso no sistema

### Verificar Logs

```bash
# Ver logs em tempo real
tail -f log/development.log | grep "notification"

# Buscar notificações específicas
grep "pending_notification" log/production.log
```

## Arquitetura

### Ficheiros Principais

```
app/
├── services/
│   └── estimate_approval_notifier.rb    # Serviço principal de notificações
├── mailers/
│   └── estimate_mailer.rb                # Mailer para emails
├── views/
│   └── estimate_mailer/
│       └── estimate_approved_notification.html.erb  # Template de email
└── controllers/
    └── estimates_controller.rb           # Controller que dispara notificações

db/
└── migrate/
    └── 20251227211500_add_director_contacts_to_company_settings.rb  # Migration de contactos
```

### Service Object: EstimateApprovalNotifier

**Responsabilidades:**
- Coordenar envio de notificações multi-canal
- Formatar mensagens para cada canal
- Registar tentativas de envio nos logs
- Gerar links do WhatsApp
- Integrar com serviços externos (futuro)

**Métodos principais:**
- `notify_directors` - Método principal que dispara notificações
- `send_whatsapp_notification` - Gera e loga mensagem WhatsApp
- `send_sms_notification` - Gera e loga mensagem SMS
- `whatsapp_message` - Formata mensagem para WhatsApp
- `sms_message` - Formata mensagem resumida para SMS

## Mensagens de Notificação

### Template Email
Ver: `app/views/estimate_mailer/estimate_approved_notification.html.erb`

### Template WhatsApp
```
🎉 *ORÇAMENTO APROVADO*

O orçamento *EST-20251227-ABC123* foi aprovado!

📋 *Detalhes:*
Cliente: Nome do Cliente
Valor: 75.000,00 AOA
Data de Aprovação: 27/12/2025 às 21:00
Aprovado por: gestor@empresa.com

✅ O cliente foi notificado por email.

Ver orçamento: https://crm.empresa.com/estimates/123
```

### Template SMS
```
ORÇAMENTO APROVADO: EST-20251227-ABC123 - Cliente: Nome do Cliente - Valor: 75.000,00 AOA - Aprovado por: gestor@empresa.com
```

## Segurança e Privacidade

- Contactos dos directores são armazenados de forma segura
- Apenas administradores podem configurar contactos
- Notificações contêm informações sensíveis - garantir canal seguro
- WhatsApp e SMS devem usar APIs oficiais em produção

## Manutenção

### Adicionar Novo Canal de Notificação

1. Adicionar método no `EstimateApprovalNotifier`
2. Chamar método em `send_notifications_to`
3. Adicionar campos na tabela `company_settings` (se necessário)
4. Atualizar formulário de configurações
5. Atualizar documentação

### Monitorar Falhas de Envio

```ruby
# Adicionar tratamento de erros
begin
  EstimateMailer.estimate_approved_notification(@estimate, email, name).deliver_later
rescue => e
  Rails.logger.error "Falha ao enviar email: #{e.message}"
  # Guardar em fila de retry
end
```

## FAQ

**Q: As notificações são enviadas imediatamente?**
A: Emails são enviados via `deliver_later` (background job). WhatsApp e SMS requerem integração manual atualmente.

**Q: O que acontece se o director não tiver email/telefone configurado?**
A: O sistema apenas envia notificações para os canais configurados. Se nenhum contacto estiver configurado, não haverá notificações.

**Q: Como personalizar as mensagens?**
A: Editar os métodos `whatsapp_message` e `sms_message` em `EstimateApprovalNotifier`.

**Q: É possível desativar notificações?**
A: Sim, basta remover os contactos nas configurações da empresa.

## Roadmap

- [ ] Integração com WhatsApp Business API
- [ ] Integração com gateway de SMS
- [ ] Painel de histórico de notificações enviadas
- [ ] Retry automático em caso de falha
- [ ] Notificações para outros eventos (rejeição, conversão para trabalho)
- [ ] Preferências de notificação por director (escolher canais)
- [ ] Templates personalizáveis de mensagens

---

**Versão:** 1.0
**Data:** 27/12/2025
**Autor:** Sistema CRM 3K
