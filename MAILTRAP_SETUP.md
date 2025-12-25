# Configuração de Email Trap com Mailtrap

Este guia explica como configurar o Mailtrap para simular envio de emails em desenvolvimento e staging/produção.

## O que é Mailtrap?

Mailtrap é um serviço de "Email Sandbox" que captura todos os emails enviados pela aplicação sem realmente enviá-los para destinatários reais. Isso é ideal para:

- **Desenvolvimento:** Testar emails sem enviar para utilizadores reais
- **Staging:** Validar emails antes de ir para produção
- **Testes automatizados:** Verificar conteúdo de emails em testes

## Passos para Configurar

### 1. Criar Conta no Mailtrap

1. Aceda a [https://mailtrap.io](https://mailtrap.io)
2. Crie uma conta gratuita
3. Confirme o seu email

### 2. Obter Credenciais SMTP

1. No painel do Mailtrap, vá para **Email Testing** > **Inboxes**
2. Selecione ou crie um inbox (ex: "CRM 3K Development")
3. Na tab **SMTP Settings**, selecione **Ruby on Rails** como integração
4. Copie as credenciais:
   - **Host:** `sandbox.smtp.mailtrap.io`
   - **Port:** `2525`
   - **Username:** (seu username único)
   - **Password:** (sua password única)

### 3. Configurar Variáveis de Ambiente

#### Desenvolvimento Local

Crie um ficheiro `.env` na raiz do projeto (copiando do `.env.example`):

```bash
cp .env.example .env
```

Edite o ficheiro `.env` e adicione as suas credenciais Mailtrap:

```env
# Mailtrap SMTP Settings
SMTP_ADDRESS=sandbox.smtp.mailtrap.io
SMTP_PORT=2525
SMTP_USERNAME=seu_username_mailtrap_aqui
SMTP_PASSWORD=sua_password_mailtrap_aqui

# Mailer Settings
MAILER_HOST=localhost
MAILER_PORT=3000
MAILER_FROM=noreply@crm3k.com
```

**IMPORTANTE:** Nunca faça commit do ficheiro `.env` para o Git! Ele já está no `.gitignore`.

#### Produção/Staging

Em produção ou staging, configure as variáveis de ambiente no seu servidor ou plataforma de hosting:

- **Heroku:** `heroku config:set SMTP_USERNAME=...`
- **AWS/DigitalOcean:** Adicione ao ficheiro de ambiente do servidor
- **Docker:** Configure no `docker-compose.yml` ou `.env.production`

### 4. Verificar Configuração

Reinicie o servidor Rails:

```bash
rails server
```

## Como Testar

### 1. Criar Novo Utilizador (Admin)

Quando um Director/Admin cria um novo utilizador:

1. Aceda à gestão de utilizadores
2. Clique em "Novo Utilizador"
3. Preencha os dados do utilizador
4. Clique em "Criar Utilizador"

**Resultado:** Nenhum email é enviado porque o utilizador é confirmado automaticamente (`skip_confirmation!`)

### 2. Auto-Registo de Utilizador

Quando um utilizador se regista pelo formulário público:

1. Aceda a [http://localhost:3000/users/sign_up](http://localhost:3000/users/sign_up)
2. Preencha os dados:
   - **Nome:** João Silva
   - **Email:** joao@example.com
   - **Palavra-passe:** MinhaPassword123!
   - **Confirmação:** MinhaPassword123!
3. Clique em "Criar Conta"

**Resultado:** Um email de confirmação é enviado para o Mailtrap!

### 3. Recuperação de Palavra-passe

1. Na página de login, clique em "Esqueceu a sua palavra-passe?"
2. Digite um email de um utilizador existente
3. Clique em "Enviar instruções de redefinição"

**Resultado:** Um email com link de reset é enviado para o Mailtrap!

### 4. Verificar Emails no Mailtrap

1. Aceda ao painel do Mailtrap
2. Abra o seu inbox
3. Veja os emails capturados
4. Clique num email para ver:
   - HTML preview
   - Texto puro
   - Headers
   - Raw source
   - Spam score

## Tipos de Emails do Sistema

O CRM 3K envia os seguintes tipos de emails:

### Devise (Autenticação)
- **Confirmação de conta** - Enviado após auto-registo
- **Redefinição de palavra-passe** - Enviado quando utilizador esquece password
- **Desbloqueio de conta** - Enviado após múltiplas tentativas falhadas
- **Notificação de alteração de email** - Enviado quando utilizador altera email

### Sistema CRM
- **Orçamentos** - Envio de orçamentos para clientes
- **Itens em Falta** - Notificações de produtos em falta
- **Relatórios** - Envio automático de relatórios
- **Subscrições** - Avisos de expiração de subscrição

## Configuração para Produção Real

Para produção com emails reais, altere as configurações SMTP para um serviço real:

### Gmail (Exemplo)

```env
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=seu_email@gmail.com
SMTP_PASSWORD=sua_senha_de_app_google
MAILER_HOST=crm3k.seudominio.com
MAILER_PORT=443
MAILER_FROM=noreply@seudominio.com
```

**Nota:** Para Gmail, precisa de:
1. Ativar autenticação em 2 fatores
2. Gerar uma "Senha de app" nas configurações da conta Google

### SendGrid, Mailgun, AWS SES

Consulte a documentação do serviço escolhido para obter credenciais SMTP.

## Resolução de Problemas

### Emails não aparecem no Mailtrap

1. Verifique se as credenciais estão corretas no `.env`
2. Reinicie o servidor Rails
3. Verifique os logs Rails: `tail -f log/development.log`
4. Teste a conexão SMTP manualmente

### Erro "Connection refused"

- Verifique se o SMTP_ADDRESS e SMTP_PORT estão corretos
- Verifique se há firewall bloqueando a porta 2525
- Tente com porta 25, 465 ou 587

### Erro "Authentication failed"

- Confirme que o SMTP_USERNAME e SMTP_PASSWORD estão corretos
- Regenere as credenciais no painel do Mailtrap

## Recursos Adicionais

- [Documentação Oficial Mailtrap](https://mailtrap.io/docs)
- [Action Mailer Guide (Rails)](https://guides.rubyonrails.org/action_mailer_basics.html)
- [Devise Email Configuration](https://github.com/heartcombo/devise/wiki/How-To:-Use-custom-mailer)

## Suporte

Para questões sobre Mailtrap, contacte o suporte do Mailtrap ou consulte a documentação oficial.
