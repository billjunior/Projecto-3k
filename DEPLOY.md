# Guia de Deploy - CRM 3K

Este guia fornece instruções passo a passo para fazer o deploy do CRM 3K em produção.

## Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração do Ambiente](#configuração-do-ambiente)
3. [Deploy no Heroku](#deploy-no-heroku)
4. [Deploy em VPS (Ubuntu)](#deploy-em-vps-ubuntu)
5. [Configuração de Email](#configuração-de-email)
6. [Configuração de SSL](#configuração-de-ssl)
7. [Manutenção e Monitoramento](#manutenção-e-monitoramento)

---

## Pré-requisitos

Antes de começar o deploy, certifique-se de ter:

- [ ] Conta em um provedor de hospedagem (Heroku, DigitalOcean, AWS, etc)
- [ ] Git instalado e repositório configurado
- [ ] Acesso SSH ao servidor (para deploy em VPS)
- [ ] Domínio configurado (opcional, mas recomendado)
- [ ] Conta de email para envio de notificações (Gmail, SendGrid, etc)

---

## Configuração do Ambiente

### 1. Variáveis de Ambiente

Crie um arquivo `.env.production` com as seguintes variáveis:

```bash
# Database
DATABASE_URL=postgresql://usuario:senha@host:5432/crm3k_production

# Rails
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=<gerar com: rails secret>

# Email (exemplo com Gmail)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=seudominio.com
SMTP_USERNAME=seuemail@gmail.com
SMTP_PASSWORD=sua_senha_de_app
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# Application
APP_HOST=crm3k.seudominio.com
APP_PROTOCOL=https

# Storage (para Active Storage)
# Se usar Amazon S3:
AWS_ACCESS_KEY_ID=sua_access_key
AWS_SECRET_ACCESS_KEY=sua_secret_key
AWS_REGION=us-east-1
AWS_BUCKET=crm3k-production

# Ou para armazenamento local:
STORAGE_SERVICE=local
```

**⚠️ IMPORTANTE**: Nunca commite o arquivo `.env.production` no Git! Adicione-o ao `.gitignore`.

### 2. Gerar SECRET_KEY_BASE

```bash
# No seu terminal local:
rails secret

# Copie o resultado e adicione ao .env.production
```

### 3. Configurar config/database.yml

```yaml
production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### 4. Configurar config/environments/production.rb

Atualize as seguintes configurações:

```ruby
# config/environments/production.rb
Rails.application.configure do
  # ... outras configurações ...

  # Email configuration
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_ADDRESS'],
    port: ENV['SMTP_PORT'],
    domain: ENV['SMTP_DOMAIN'],
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: ENV['SMTP_AUTHENTICATION'],
    enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == 'true'
  }

  config.action_mailer.default_url_options = {
    host: ENV['APP_HOST'],
    protocol: ENV['APP_PROTOCOL'] || 'https'
  }

  # Active Storage
  config.active_storage.service = ENV['STORAGE_SERVICE']&.to_sym || :amazon

  # Force SSL
  config.force_ssl = true
end
```

---

## Deploy no Heroku

### Passo 1: Instalar Heroku CLI

```bash
# macOS
brew tap heroku/brew && brew install heroku

# Ubuntu
curl https://cli-assets.heroku.com/install.sh | sh

# Verificar instalação
heroku --version
```

### Passo 2: Login no Heroku

```bash
heroku login
```

### Passo 3: Criar Aplicação

```bash
# Na raiz do projeto
heroku create crm3k-production

# Adicionar PostgreSQL
heroku addons:create heroku-postgresql:mini

# Verificar banco de dados criado
heroku pg:info
```

### Passo 4: Configurar Variáveis de Ambiente

```bash
# Gerar SECRET_KEY_BASE
heroku config:set SECRET_KEY_BASE=$(rails secret)

# Configurar email (exemplo com SendGrid)
heroku addons:create sendgrid:starter
# OU configurar manualmente:
heroku config:set SMTP_ADDRESS=smtp.sendgrid.net
heroku config:set SMTP_PORT=587
heroku config:set SMTP_USERNAME=apikey
heroku config:set SMTP_PASSWORD=sua_api_key_do_sendgrid

# Configurar host
heroku config:set APP_HOST=crm3k-production.herokuapp.com
heroku config:set APP_PROTOCOL=https

# Ver todas as configurações
heroku config
```

### Passo 5: Deploy

```bash
# Fazer commit de todas as alterações
git add .
git commit -m "Preparar para deploy em produção"

# Deploy
git push heroku main

# OU se estiver em outra branch:
git push heroku sua-branch:main
```

### Passo 6: Executar Migrations

```bash
heroku run rails db:migrate
```

### Passo 7: Criar Seed Inicial

```bash
# Se tiver seeds para produção
heroku run rails db:seed

# OU criar tenant e usuário manualmente:
heroku run rails console
```

No console Rails:

```ruby
# Criar tenant
tenant = Tenant.create!(
  name: "Sua Empresa",
  subdomain: "suaempresa",
  status: :active,
  subscription_start: Date.today,
  subscription_end: 1.year.from_now
)

# Criar usuário admin
ActsAsTenant.current_tenant = tenant
user = User.create!(
  tenant: tenant,
  name: "Administrador",
  email: "admin@suaempresa.com",
  password: "senha_segura_aqui",
  password_confirmation: "senha_segura_aqui",
  role: :commercial,
  admin: true,
  super_admin: true,
  confirmed_at: Time.now
)

puts "Tenant e usuário criados com sucesso!"
exit
```

### Passo 8: Abrir Aplicação

```bash
heroku open
```

### Passo 9: Configurar Domínio Customizado (Opcional)

```bash
# Adicionar domínio
heroku domains:add crm.seudominio.com

# Heroku vai fornecer um DNS target
# Configure um registro CNAME no seu provedor de domínio apontando para esse target

# Configurar SSL automático
heroku certs:auto:enable

# Atualizar variável de ambiente
heroku config:set APP_HOST=crm.seudominio.com
```

---

## Deploy em VPS (Ubuntu)

Este guia usa Ubuntu 22.04 LTS com Nginx, Passenger e PostgreSQL.

### Passo 1: Preparar Servidor

```bash
# Conectar ao servidor
ssh usuario@seu-servidor.com

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y curl gnupg2 build-essential git-core \
  zlib1g-dev libssl-dev libreadline-dev libyaml-dev \
  libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev \
  libcurl4-openssl-dev software-properties-common \
  libffi-dev nodejs yarn
```

### Passo 2: Instalar Ruby

```bash
# Instalar RVM
gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm

# Instalar Ruby 3.0.0
rvm install 3.0.0
rvm use 3.0.0 --default

# Verificar instalação
ruby -v
gem -v
```

### Passo 3: Instalar PostgreSQL

```bash
# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-contrib libpq-dev

# Criar usuário e banco de dados
sudo -u postgres psql

# No console PostgreSQL:
CREATE USER crm3k_user WITH PASSWORD 'senha_segura_aqui';
CREATE DATABASE crm3k_production OWNER crm3k_user;
ALTER USER crm3k_user CREATEDB;
\q
```

### Passo 4: Instalar Nginx e Passenger

```bash
# Instalar chaves do Passenger
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7

# Adicionar repositório
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger jammy main > /etc/apt/sources.list.d/passenger.list'

# Atualizar e instalar
sudo apt update
sudo apt install -y nginx libnginx-mod-http-passenger

# Verificar instalação
sudo passenger-config validate-install
```

### Passo 5: Configurar Aplicação

```bash
# Criar diretório para a aplicação
sudo mkdir -p /var/www/crm3k
sudo chown $USER:$USER /var/www/crm3k

# Clonar repositório
cd /var/www
git clone https://github.com/seu-usuario/crm3k.git
cd crm3k

# Instalar gems
bundle install --deployment --without development test

# Criar arquivo de variáveis de ambiente
nano .env.production
# Cole as variáveis de ambiente aqui

# Carregar variáveis de ambiente
export $(cat .env.production | xargs)

# Precompilar assets
RAILS_ENV=production rails assets:precompile

# Executar migrations
RAILS_ENV=production rails db:migrate

# Criar tenant e usuário (igual ao Heroku)
RAILS_ENV=production rails console
# Execute os comandos Ruby do Passo 7 do Heroku
```

### Passo 6: Configurar Nginx

```bash
# Criar arquivo de configuração
sudo nano /etc/nginx/sites-available/crm3k
```

Cole o seguinte conteúdo:

```nginx
server {
    listen 80;
    server_name crm.seudominio.com;

    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name crm.seudominio.com;

    # SSL (vamos configurar com Let's Encrypt depois)
    ssl_certificate /etc/letsencrypt/live/crm.seudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/crm.seudominio.com/privkey.pem;

    root /var/www/crm3k/public;

    # Passenger
    passenger_enabled on;
    passenger_app_env production;
    passenger_ruby /home/usuario/.rvm/gems/ruby-3.0.0/wrappers/ruby;

    # Logs
    access_log /var/log/nginx/crm3k_access.log;
    error_log /var/log/nginx/crm3k_error.log;

    # Client max body size (para uploads)
    client_max_body_size 50M;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    location ~ ^/(assets|packs)/ {
        gzip_static on;
        expires max;
        add_header Cache-Control public;
    }
}
```

```bash
# Ativar site
sudo ln -s /etc/nginx/sites-available/crm3k /etc/nginx/sites-enabled/

# Remover configuração padrão
sudo rm /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t

# Recarregar Nginx
sudo systemctl reload nginx
```

### Passo 7: Configurar SSL com Let's Encrypt

```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obter certificado (antes, remova as linhas SSL do nginx temporariamente)
sudo certbot --nginx -d crm.seudominio.com

# Certbot vai automaticamente configurar o Nginx
# E criar um cron job para renovação automática

# Verificar renovação automática
sudo certbot renew --dry-run
```

### Passo 8: Configurar Firewall

```bash
# Permitir SSH, HTTP e HTTPS
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'

# Ativar firewall
sudo ufw enable

# Verificar status
sudo ufw status
```

### Passo 9: Configurar Reinicialização Automática

```bash
# Criar serviço systemd
sudo nano /etc/systemd/system/crm3k.service
```

Cole:

```ini
[Unit]
Description=CRM 3K Rails Application
After=network.target

[Service]
Type=notify
User=usuario
WorkingDirectory=/var/www/crm3k
Environment=RAILS_ENV=production
Environment=PORT=3000
ExecStart=/home/usuario/.rvm/gems/ruby-3.0.0/wrappers/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Ativar serviço
sudo systemctl enable crm3k
sudo systemctl start crm3k
sudo systemctl status crm3k
```

---

## Configuração de Email

### Opção 1: Gmail (Desenvolvimento/Pequena Escala)

```bash
# Configurar variáveis de ambiente
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
SMTP_USERNAME=seuemail@gmail.com
SMTP_PASSWORD=senha_de_app_do_gmail  # Gerar em: myaccount.google.com/apppasswords
```

### Opção 2: SendGrid (Recomendado para Produção)

```bash
# Criar conta em sendgrid.com
# Obter API Key

# Configurar variáveis
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=sua_sendgrid_api_key
```

### Opção 3: Amazon SES

```bash
# Configurar IAM user na AWS
# Obter SMTP credentials

SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USERNAME=seu_smtp_username
SMTP_PASSWORD=seu_smtp_password
```

### Testar Email

```bash
# Em produção (Heroku)
heroku run rails console

# Em VPS
RAILS_ENV=production rails console

# No console Rails:
ActionMailer::Base.mail(
  from: 'noreply@seudominio.com',
  to: 'seuemail@teste.com',
  subject: 'Teste de Email CRM 3K',
  body: 'Se você recebeu este email, a configuração está funcionando!'
).deliver_now
```

---

## Configuração de SSL

### Heroku (Automático)

```bash
# SSL automático já está incluído no Heroku
# Para domínio customizado:
heroku certs:auto:enable
```

### VPS com Let's Encrypt (Já coberto no Passo 7 acima)

```bash
# Renovação automática já está configurada
# Verificar status:
sudo certbot certificates

# Forçar renovação:
sudo certbot renew --force-renewal
```

---

## Manutenção e Monitoramento

### Logs

**Heroku:**
```bash
# Ver logs em tempo real
heroku logs --tail

# Ver últimos 1000 logs
heroku logs -n 1000

# Filtrar por tipo
heroku logs --source app --tail
```

**VPS:**
```bash
# Logs da aplicação
tail -f /var/www/crm3k/log/production.log

# Logs do Nginx
tail -f /var/log/nginx/crm3k_access.log
tail -f /var/log/nginx/crm3k_error.log

# Logs do sistema
journalctl -u crm3k -f
```

### Backup do Banco de Dados

**Heroku:**
```bash
# Backup manual
heroku pg:backups:capture

# Baixar backup
heroku pg:backups:download

# Agendar backups automáticos
heroku pg:backups:schedule DATABASE_URL --at '02:00 America/Sao_Paulo'
```

**VPS:**
```bash
# Criar script de backup
sudo nano /usr/local/bin/backup-crm3k.sh
```

Cole:

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/crm3k"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/crm3k_$TIMESTAMP.sql.gz"

# Criar diretório se não existir
mkdir -p $BACKUP_DIR

# Fazer backup
pg_dump -U crm3k_user crm3k_production | gzip > $BACKUP_FILE

# Manter apenas últimos 7 backups
find $BACKUP_DIR -name "crm3k_*.sql.gz" -mtime +7 -delete

echo "Backup criado: $BACKUP_FILE"
```

```bash
# Dar permissão de execução
sudo chmod +x /usr/local/bin/backup-crm3k.sh

# Agendar backup diário (2h da manhã)
sudo crontab -e
# Adicionar linha:
0 2 * * * /usr/local/bin/backup-crm3k.sh
```

### Atualização da Aplicação

**Heroku:**
```bash
# Fazer alterações no código
git add .
git commit -m "Suas alterações"
git push heroku main

# Executar migrations se necessário
heroku run rails db:migrate

# Reiniciar se necessário
heroku restart
```

**VPS:**
```bash
# Conectar ao servidor
ssh usuario@seu-servidor.com

# Navegar para o diretório
cd /var/www/crm3k

# Fazer backup antes de atualizar
sudo /usr/local/bin/backup-crm3k.sh

# Baixar atualizações
git pull origin main

# Instalar novas gems
bundle install --deployment

# Executar migrations
RAILS_ENV=production rails db:migrate

# Precompilar assets
RAILS_ENV=production rails assets:precompile

# Reiniciar aplicação
sudo systemctl restart crm3k
# OU
passenger-config restart-app /var/www/crm3k
```

### Monitoramento

**Recomendações de ferramentas:**

1. **New Relic** - Monitoramento de performance
2. **Sentry** - Rastreamento de erros
3. **UptimeRobot** - Verificação de disponibilidade
4. **Loggly** - Agregação de logs

**Configurar New Relic (opcional):**
```bash
# Adicionar ao Gemfile
gem 'newrelic_rpm'

# Heroku
heroku addons:create newrelic:wayne

# VPS - Baixar configuração
# Seguir instruções em: newrelic.com
```

---

## Troubleshooting

### Problema: Aplicação não inicia

**Heroku:**
```bash
heroku logs --tail
heroku ps
heroku restart
```

**VPS:**
```bash
sudo systemctl status crm3k
sudo journalctl -u crm3k -n 100
passenger-status
```

### Problema: Erros de banco de dados

```bash
# Verificar conexão
heroku pg:info  # Heroku
sudo -u postgres psql -l  # VPS

# Executar migrations
heroku run rails db:migrate  # Heroku
RAILS_ENV=production rails db:migrate  # VPS
```

### Problema: Assets não carregam

```bash
# Recompilar assets
RAILS_ENV=production rails assets:clobber
RAILS_ENV=production rails assets:precompile

# Verificar permissões (VPS)
sudo chown -R www-data:www-data /var/www/crm3k/public
```

### Problema: Emails não enviam

```bash
# Verificar configurações
heroku config | grep SMTP  # Heroku

# Testar no console
rails console
ActionMailer::Base.smtp_settings
```

---

## Checklist Final

Antes de considerar o deploy completo, verifique:

- [ ] Aplicação acessível via HTTPS
- [ ] Banco de dados configurado e migrations executadas
- [ ] Tenant e usuário admin criados
- [ ] Emails sendo enviados corretamente
- [ ] SSL configurado e válido
- [ ] Backups automáticos configurados
- [ ] Logs sendo gerados e acessíveis
- [ ] Variáveis de ambiente configuradas
- [ ] Domínio customizado funcionando (se aplicável)
- [ ] Firewall configurado (VPS)
- [ ] Monitoramento configurado
- [ ] Documentação atualizada

---

## Suporte

Para problemas ou dúvidas:

1. Verificar logs da aplicação
2. Consultar documentação do Rails: guides.rubyonrails.org
3. Verificar status dos serviços: status.heroku.com (se usando Heroku)
4. Abrir issue no repositório do projeto

---

## Recursos Adicionais

- [Heroku Rails Documentation](https://devcenter.heroku.com/articles/getting-started-with-rails7)
- [Passenger Documentation](https://www.phusionpassenger.com/docs/tutorials/deploy_to_production/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

**Última atualização:** Dezembro 2025
**Versão:** 1.0
