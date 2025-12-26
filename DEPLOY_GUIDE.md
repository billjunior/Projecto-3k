# Guia de Deploy - CRM 3K

## Opção 1: Deploy com Render (Recomendado) 🚀

### Vantagens:
- ✅ Tier gratuito (750 horas/mês)
- ✅ PostgreSQL incluído (gratuito)
- ✅ Deploy automático via Git
- ✅ SSL certificado gratuito
- ✅ Fácil configuração

### Passo a Passo:

#### 1. Criar conta no Render
- Acesse: https://render.com
- Crie conta (pode usar GitHub)

#### 2. Fazer Push do Código para GitHub
```bash
# Se ainda não tem repositório no GitHub
git remote add origin https://github.com/seu-usuario/crm_3k.git
git push -u origin main
```

#### 3. Configurar no Render Dashboard

**3.1. Criar Novo Web Service:**
- Clique "New +" → "Web Service"
- Conecte seu repositório GitHub
- Selecione o repositório `crm_3k`

**3.2. Configurações:**
- **Name:** crm-3k (ou outro nome)
- **Environment:** Ruby
- **Region:** Frankfurt (mais próximo de Angola)
- **Branch:** main
- **Build Command:** `./bin/render-build.sh`
- **Start Command:** `bundle exec puma -C config/puma.rb`
- **Instance Type:** Free

**3.3. Variáveis de Ambiente (Environment Variables):**
Adicione estas variáveis no painel Render:

```
RAILS_MASTER_KEY=<conteúdo do config/master.key>
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
DATABASE_URL=<será preenchido automaticamente pelo Render>
```

**Como obter RAILS_MASTER_KEY:**
```bash
cat config/master.key
```

#### 4. Criar Database
- No Dashboard Render, clique "New +" → "PostgreSQL"
- **Name:** crm-3k-db
- **Database:** crm_3k_production
- **User:** crm3k
- **Region:** Frankfurt (mesma do web service)
- **Plan:** Free

#### 5. Conectar Database ao Web Service
- Vá ao Web Service criado
- Em "Environment", adicione:
  - Key: `DATABASE_URL`
  - Value: Selecione o database criado

#### 6. Deploy
- Clique "Create Web Service"
- Aguarde o build (5-10 minutos primeira vez)
- Acesse a URL fornecida: `https://crm-3k.onrender.com`

---

## Opção 2: Deploy com Fly.io 🪂

### Vantagens:
- ✅ Moderna e rápida
- ✅ Tier gratuito generoso
- ✅ Suporta múltiplas regiões
- ✅ Excelente para Rails

### Passo a Passo:

#### 1. Instalar Fly CLI
```bash
# macOS
brew install flyctl

# Linux
curl -L https://fly.io/install.sh | sh

# Windows
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

#### 2. Login
```bash
flyctl auth login
```

#### 3. Inicializar App
```bash
cd /Users/newuser/crm_3k
flyctl launch

# Responda as perguntas:
# - App name: crm-3k (ou outro)
# - Region: ams (Amsterdam, mais próximo)
# - PostgreSQL: Yes
# - Redis: No (por enquanto)
```

#### 4. Configurar Secrets
```bash
# Rails Master Key
flyctl secrets set RAILS_MASTER_KEY=$(cat config/master.key)

# Outras variáveis
flyctl secrets set RAILS_ENV=production
flyctl secrets set RAILS_LOG_TO_STDOUT=true
flyctl secrets set RAILS_SERVE_STATIC_FILES=true
```

#### 5. Deploy
```bash
flyctl deploy
```

#### 6. Executar Migrations
```bash
flyctl ssh console
cd /app
bin/rails db:migrate
exit
```

#### 7. Acessar App
```bash
flyctl open
```

---

## Opção 3: Deploy com DigitalOcean (VPS) 💧

### Para quem quer mais controle:

#### 1. Criar Droplet
- Acesse DigitalOcean
- Crie Droplet Ubuntu 22.04
- Tamanho: $6/mês (1GB RAM)

#### 2. Conectar via SSH
```bash
ssh root@seu-ip
```

#### 3. Instalar Dependências
```bash
# Atualizar sistema
apt update && apt upgrade -y

# Instalar Ruby
apt install -y curl gpg build-essential
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm install 3.1.6
rvm use 3.1.6 --default

# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Instalar PostgreSQL
apt install -y postgresql postgresql-contrib libpq-dev

# Instalar Nginx
apt install -y nginx
```

#### 4. Configurar PostgreSQL
```bash
sudo -u postgres psql
CREATE USER crm3k WITH PASSWORD 'senha_segura';
CREATE DATABASE crm_3k_production OWNER crm3k;
\q
```

#### 5. Deploy da Aplicação
```bash
# Clonar repositório
cd /var/www
git clone https://github.com/seu-usuario/crm_3k.git
cd crm_3k

# Instalar gems
bundle install --deployment --without development test

# Configurar variáveis
export RAILS_ENV=production
export RAILS_MASTER_KEY=<seu-master-key>
export DATABASE_URL=postgresql://crm3k:senha_segura@localhost/crm_3k_production

# Precompilar assets
bundle exec rake assets:precompile

# Executar migrations
bundle exec rake db:migrate

# Criar seed inicial (se necessário)
bundle exec rake db:seed
```

#### 6. Configurar Nginx
```bash
nano /etc/nginx/sites-available/crm3k
```

Adicione:
```nginx
upstream crm3k {
  server unix:///var/www/crm_3k/tmp/sockets/puma.sock fail_timeout=0;
}

server {
  listen 80;
  server_name seu-dominio.com;

  root /var/www/crm_3k/public;

  location / {
    try_files $uri @app;
  }

  location @app {
    proxy_pass http://crm3k;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
  }
}
```

```bash
ln -s /etc/nginx/sites-available/crm3k /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

#### 7. Configurar Systemd para Puma
```bash
nano /etc/systemd/system/puma.service
```

Adicione:
```ini
[Unit]
Description=Puma HTTP Server for CRM 3K
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/crm_3k
Environment=RAILS_ENV=production
Environment=RAILS_MASTER_KEY=<seu-master-key>
Environment=DATABASE_URL=postgresql://crm3k:senha_segura@localhost/crm_3k_production
ExecStart=/usr/local/rvm/gems/ruby-3.1.6/wrappers/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable puma
systemctl start puma
systemctl status puma
```

---

## Opção 4: Deploy com Heroku (Pago) 💰

### Nota: Heroku não tem mais tier gratuito desde Nov 2022

```bash
# Instalar Heroku CLI
brew install heroku/brew/heroku

# Login
heroku login

# Criar app
heroku create crm-3k

# Adicionar PostgreSQL
heroku addons:create heroku-postgresql:mini

# Configurar variáveis
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
heroku config:set RAILS_ENV=production

# Deploy
git push heroku main

# Executar migrations
heroku run rails db:migrate

# Abrir app
heroku open
```

**Custo:** ~$7-25/mês (dyno + database)

---

## Checklist Pré-Deploy ✅

Antes de fazer deploy, certifique-se:

- [ ] `config/master.key` existe e está no `.gitignore`
- [ ] `config/credentials.yml.enc` está commitado
- [ ] Variáveis de ambiente configuradas
- [ ] Database configurado para PostgreSQL em produção
- [ ] Assets precompilados funcionando
- [ ] CORS configurado se necessário
- [ ] Secrets seguros (não hardcoded)
- [ ] Backup strategy definida

---

## Configurações de Produção Importantes

### 1. Database (config/database.yml)
```yaml
production:
  <<: *default
  database: crm_3k_production
  url: <%= ENV['DATABASE_URL'] %>
```

### 2. Puma (config/puma.rb)
```ruby
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

port ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

workers ENV.fetch("WEB_CONCURRENCY") { 2 }
preload_app!

plugin :tmp_restart
```

### 3. Credentials
```bash
# Editar credentials
EDITOR=nano rails credentials:edit

# Deve conter:
# - secret_key_base
# - database passwords
# - API keys
```

---

## Domínio Personalizado

### Render:
1. Vá em Settings → Custom Domains
2. Adicione seu domínio: `www.seucrm.com`
3. Configure DNS:
   - CNAME: `www` → `crm-3k.onrender.com`

### Fly.io:
```bash
flyctl certs add www.seucrm.com
```

Configure DNS:
- A: `@` → IP fornecido pelo Fly
- AAAA: `@` → IPv6 fornecido pelo Fly

---

## Monitoramento

### Logs (Render):
```bash
# Ver logs em tempo real
render logs -a crm-3k
```

### Logs (Fly.io):
```bash
flyctl logs
```

### Logs (DigitalOcean):
```bash
ssh root@seu-ip
journalctl -u puma -f
```

---

## Backup Database

### Render:
```bash
# Manual backup via dashboard
# Settings → Backups → Create Snapshot
```

### Fly.io:
```bash
flyctl postgres backup list
flyctl postgres backup create
```

### DigitalOcean:
```bash
# Criar backup
pg_dump -U crm3k -h localhost crm_3k_production > backup_$(date +%Y%m%d).sql

# Restaurar backup
psql -U crm3k -h localhost crm_3k_production < backup_20231226.sql
```

---

## Troubleshooting Comum

### 1. "We're sorry, but something went wrong"
- Verifique logs: `flyctl logs` ou Render dashboard
- Provavelmente falta `RAILS_MASTER_KEY`

### 2. Assets não carregam
- Verifique `RAILS_SERVE_STATIC_FILES=true`
- Re-precompile: `bundle exec rake assets:precompile`

### 3. Database connection error
- Verifique `DATABASE_URL` está configurada
- Teste conexão: `flyctl ssh console -C "rails db:migrate:status"`

### 4. Out of Memory
- Render Free: limitado a 512MB
- Solução: Upgrade para paid tier ou otimizar queries

---

## Custos Estimados

| Plataforma | Free Tier | Paid Tier | Database |
|------------|-----------|-----------|----------|
| **Render** | 750h/mês | $7/mês | Free (1GB) ou $7/mês |
| **Fly.io** | 3 VMs gratuitas | $1.94/mês por VM | $0 (3GB) ou paid |
| **Heroku** | ❌ Não existe | $7/mês (Eco) | $5/mês (Mini) |
| **DigitalOcean** | ❌ | $6/mês (1GB) | Incluído no droplet |

---

## Recomendação Final

**Para começar (gratuito):** Use **Render**
- Setup mais fácil
- Database PostgreSQL incluído
- SSL automático
- Good enough para produção leve

**Para escalar (melhor custo/benefício):** Use **Fly.io**
- Mais rápido
- Múltiplas regiões
- Melhor pricing em escala

**Para controle total:** Use **DigitalOcean/AWS**
- Mais trabalho inicial
- Total flexibilidade
- Melhor para equipes técnicas
