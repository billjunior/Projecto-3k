# Seeds para CRM 3K - Gráfica e CyberCafé Multi-Tenant
puts "Criando dados de exemplo..."

# Limpar dados existentes
[Payment, InvoiceItem, Invoice, JobFile, JobItem, Job, EstimateItem, Estimate,
 LanSession, LanMachine, Task, PriceRule, Product, Customer, User, Tenant].each(&:destroy_all)

# Criar Tenant Demo
puts "Criando tenant demo..."
tenant = Tenant.create!(
  name: "CRM 3K",
  subdomain: "demo",
  status: :active,
  subscription_start: Date.today,
  subscription_end: Date.today + 1.year,
  settings: {
    primary_color: "#007bff",
    secondary_color: "#6c757d",
    currency: "AOA",
    tax_rate: 14
  }
)

puts "  Tenant criado: #{tenant.name}"

# Set current tenant for all subsequent operations
ActsAsTenant.current_tenant = tenant

# Criar usuários com nova arquitetura de segurança
puts "Criando usuários..."

# Super Admin - Director (Acesso Total: CRM + Cyber)
super_admin = User.create!(
  name: "Director Geral",
  email: "director@3k.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  role: :commercial,
  super_admin: true,
  admin: false,
  active: true,
  confirmed_at: Time.current
)
puts "  - Super Admin (Director): director@3k.com"

# Admin - Directora Financeira (Acesso Total CRM, SEM Cyber)
directora_financeira = User.create!(
  name: "Ana Directora Financeira",
  email: "financeira@3k.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  role: :commercial,
  admin: true,
  super_admin: false,
  department: :financial,
  active: true,
  confirmed_at: Time.current
)
puts "  - Admin Financeira: financeira@3k.com"

# Commercial - Assistente Comercial (CRM completo, SEM Cyber)
assistente_comercial = User.create!(
  name: "João Assistente Comercial",
  email: "comercial@3k.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  role: :commercial,
  admin: false,
  super_admin: false,
  department: :commercial_dept,
  active: true,
  confirmed_at: Time.current
)
puts "  - Comercial: comercial@3k.com"

# Cyber Tech - Técnico Cyber Café (APENAS Cyber, SEM CRM)
tecnico_cyber = User.create!(
  name: "Pedro Técnico Cyber",
  email: "cyber@3k.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  role: :cyber_tech,
  admin: false,
  super_admin: false,
  department: :technical_dept,
  active: true,
  confirmed_at: Time.current
)
puts "  - Técnico Cyber: cyber@3k.com"

# Attendant - Atendente (Acesso limitado CRM)
atendente = User.create!(
  name: "Maria Atendente",
  email: "atendente@3k.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  role: :attendant,
  admin: false,
  super_admin: false,
  active: true,
  confirmed_at: Time.current
)
puts "  - Atendente: atendente@3k.com"

# Production - Produção (Apenas Jobs)
producao = User.create!(
  name: "Carlos Produção",
  email: "producao@3k.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  role: :production,
  admin: false,
  super_admin: false,
  active: true,
  confirmed_at: Time.current
)
puts "  - Produção: producao@3k.com"

puts "  Criados #{User.count} usuários"

# Criar clientes
puts "Criando clientes..."
clientes = []

5.times do |i|
  clientes << Customer.create!(
    name: "Cliente Particular #{i + 1}",
    customer_type: "particular",
    phone: "244#{900000000 + i}",
    whatsapp: "244#{900000000 + i}",
    email: "cliente#{i + 1}@example.com",
    address: "Rua #{i + 1}, Luanda"
  )
end

3.times do |i|
  clientes << Customer.create!(
    name: "Empresa #{i + 1} Lda",
    customer_type: "empresa",
    tax_id: "#{5000000000 + i}",
    phone: "244#{920000000 + i}",
    email: "empresa#{i + 1}@example.com",
    address: "Av. Principal #{i + 1}, Luanda"
  )
end

puts "  Criados #{Customer.count} clientes"

# Criar produtos da gráfica
puts "Criando produtos..."
produtos_grafica = [
  { name: "Cartão de visita 9x5 (100 un)", category: "grafica", unit: "unidade", base_price: 2500 },
  { name: "Flyer A5 (100 un)", category: "grafica", unit: "unidade", base_price: 5000 },
  { name: "Banner 1x1m", category: "grafica", unit: "unidade", base_price: 8000 },
  { name: "T-shirt Estampada", category: "grafica", unit: "unidade", base_price: 3500 },
  { name: "Caneca Personalizada", category: "grafica", unit: "unidade", base_price: 2000 }
]

produtos_lanhouse = [
  { name: "Hora de Computador", category: "lanhouse", unit: "hora", base_price: 500 },
  { name: "Impressão A4 P&B", category: "lanhouse", unit: "página", base_price: 50 },
  { name: "Impressão A4 Cor", category: "lanhouse", unit: "página", base_price: 200 },
  { name: "Pacote 5 Horas", category: "lanhouse", unit: "pacote", base_price: 2000 }
]

produtos = []
(produtos_grafica + produtos_lanhouse).each do |attrs|
  produtos << Product.create!(attrs.merge(active: true))
end

puts "  Criados #{Product.count} produtos"

# Criar máquinas LAN
puts "Criando máquinas do CyberCafé..."
10.times do |i|
  LanMachine.create!(
    name: "PC-#{sprintf('%02d', i + 1)}",
    status: "livre",
    hourly_rate: 500,
    notes: "Computador #{i + 1}"
  )
end

puts "  Criadas #{LanMachine.count} máquinas"

puts "\nDados de exemplo criados com sucesso!"
puts "\n" + "="*80
puts "=== ARQUITETURA DE SEGURANÇA - USUÁRIOS DE TESTE ==="
puts "="*80
puts "\n1. SUPER ADMIN (Director) - Acesso Total (CRM + Cyber)"
puts "   Email: director@3k.com"
puts "   Senha: Password123!"
puts "   Permissões: Tudo"
puts "\n2. ADMIN (Directora Financeira) - Acesso Total CRM, SEM Cyber"
puts "   Email: financeira@3k.com"
puts "   Senha: Password123!"
puts "   Permissões: CRM completo, relatórios financeiros, SEM acesso Cyber"
puts "\n3. COMMERCIAL (Assistente Comercial) - CRM Completo"
puts "   Email: comercial@3k.com"
puts "   Senha: Password123!"
puts "   Permissões: Leads, Oportunidades, Clientes, Orçamentos, Trabalhos, Faturas"
puts "\n4. CYBER TECH (Técnico Cyber) - APENAS Cyber Café"
puts "   Email: cyber@3k.com"
puts "   Senha: Password123!"
puts "   Permissões: Máquinas LAN, Sessões, Inventário, Receitas Diárias, Cursos"
puts "   BLOQUEADO: Acesso ao CRM principal"
puts "\n5. ATTENDANT (Atendente) - Acesso Limitado"
puts "   Email: atendente@3k.com"
puts "   Senha: Password123!"
puts "   Permissões: Visualizar clientes, criar orçamentos"
puts "\n6. PRODUCTION (Produção) - Apenas Trabalhos"
puts "   Email: producao@3k.com"
puts "   Senha: Password123!"
puts "   Permissões: Visualizar e atualizar trabalhos, upload de arquivos"
puts "\n" + "="*80
puts "NOTA: Todos os usuários confirmados automaticamente para teste"
puts "="*80
