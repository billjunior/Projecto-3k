# Seeds para CRM 3K - Gráfica e CyberCafé Multi-Tenant
puts "Criando dados de exemplo..."

# Limpar dados existentes
[Payment, InvoiceItem, Invoice, JobFile, JobItem, Job, EstimateItem, Estimate,
 LanSession, LanMachine, Task, PriceRule, Product, Customer, Service, AuditLog, User, Tenant].each(&:destroy_all)

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

# Directora Financeira (Acesso Total igual ao Director: CRM + Cyber + Gestão de Usuários)
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
puts "  - Directora Financeira (Super Admin): financeira@3k.com"

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

# Criar Serviços do Catálogo
puts "\nCriando catálogo de serviços..."

ActsAsTenant.with_tenant(tenant) do
  # Impressões Rápidas e Documentos
  Service.create!([
    {
      category: 'Impressões Rápidas e Documentos',
      name: 'Impressão Digital A4/A3',
      description: 'Folhetos, relatórios, cópias coloridas',
      estimated_time: '15-30 min',
      availability: 'Na hora',
      active: true
    },
    {
      category: 'Impressões Rápidas e Documentos',
      name: 'Impressão Laser Preto e Branco',
      description: 'Documentos, faturas, formulários',
      estimated_time: '10-20 min',
      availability: 'Na hora',
      active: true
    },
    {
      category: 'Impressões Rápidas e Documentos',
      name: 'Impressão Fotográfica',
      description: 'Fotos, quadros, posters',
      estimated_time: '20-40 min',
      availability: 'Na hora',
      active: true
    },
    {
      category: 'Impressões Rápidas e Documentos',
      name: 'Digitalização e Cópias',
      description: 'Documentos e imagens',
      estimated_time: '10-15 min',
      availability: 'Na hora',
      active: true
    },
    {
      category: 'Impressões Rápidas e Documentos',
      name: 'Impressão Frente e Verso (Duplex)',
      description: 'Apostilas, manuais, boletins',
      estimated_time: '15-30 min',
      availability: 'Na hora',
      active: true
    },
    {
      category: 'Impressões Rápidas e Documentos',
      name: 'Encadernação Rápida (Grampos, Espiral)',
      description: 'Trabalhos escolares, relatórios',
      estimated_time: '10-20 min',
      availability: 'Na hora',
      active: true
    },

    # Personalização
    {
      category: 'Personalização',
      name: 'Carimbos Personalizados',
      description: 'Nome, cargo, empresa, logotipo',
      estimated_time: '30-60 min',
      availability: 'Na hora',
      active: true
    },
    {
      category: 'Personalização',
      name: 'Cartões de Visita',
      description: 'Design personalizado, impressão de qualidade',
      estimated_time: '24 horas',
      availability: '24 horas',
      active: true
    },
    {
      category: 'Personalização',
      name: 'Banners e Lonas',
      description: 'Publicidade exterior, eventos',
      estimated_time: '48 horas',
      availability: '48 horas',
      active: true
    },

    # Design Gráfico
    {
      category: 'Design Gráfico',
      name: 'Criação de Logotipo',
      description: 'Identidade visual da empresa',
      estimated_time: '3-5 dias',
      availability: 'Sob consulta',
      active: true
    },
    {
      category: 'Design Gráfico',
      name: 'Design de Folhetos',
      description: 'Material publicitário',
      estimated_time: '1-2 dias',
      availability: 'Sob consulta',
      active: true
    },

    # Encadernação
    {
      category: 'Encadernação',
      name: 'Encadernação Térmica',
      description: 'Acabamento profissional para documentos',
      estimated_time: '30-60 min',
      availability: 'Na hora',
      active: true
    },
    {
      category: 'Encadernação',
      name: 'Encadernação Capa Dura',
      description: 'Teses, projetos acadêmicos',
      estimated_time: '24 horas',
      availability: '24 horas',
      active: true
    }
  ])
end

puts "  Criados #{Service.count} serviços no catálogo"

puts "\nDados de exemplo criados com sucesso!"
puts "\n" + "="*80
puts "=== CREDENCIAIS DE ACESSO - CRM 3K ==="
puts "="*80
puts "\n1. DIRECTOR GERAL - Super Admin"
puts "   Email: director@3k.com"
puts "   Senha: Password123!"
puts "   Acesso: TOTAL (CRM + Cyber + Admin Panel + Gestão de Usuários)"
puts "\n2. DIRECTORA FINANCEIRA - Equivalente Super Admin"
puts "   Email: financeira@3k.com"
puts "   Senha: Password123!"
puts "   Acesso: TOTAL (CRM + Cyber + Gestão de Usuários + Relatórios Financeiros)"
puts "   Pode: Resetar senhas, bloquear/desbloquear contas"
puts "\n3. ASSISTENTE COMERCIAL"
puts "   Email: comercial@3k.com"
puts "   Senha: Password123!"
puts "   Acesso: CRM Completo (Leads, Oportunidades, Clientes, Produtos, Orçamentos, Trabalhos, Faturas)"
puts "\n4. TÉCNICO CYBER CAFÉ"
puts "   Email: cyber@3k.com"
puts "   Senha: Password123!"
puts "   Acesso: APENAS Cyber Café (Máquinas, Sessões, Inventário, Receitas Diárias, Cursos)"
puts "\n5. ATENDENTE"
puts "   Email: atendente@3k.com"
puts "   Senha: Password123!"
puts "   Acesso: CRM Limitado (Leads, Oportunidades, Clientes, Orçamentos, Trabalhos, Tarefas)"
puts "\n6. PRODUÇÃO"
puts "   Email: producao@3k.com"
puts "   Senha: Password123!"
puts "   Acesso: Apenas Trabalhos e Tarefas"
puts "\n" + "="*80
puts "IMPORTANTES MUDANÇAS:"
puts "- Director e Directora Financeira têm as MESMAS permissões"
puts "- Ambos podem gerir usuários (criar, editar, resetar senhas, bloquear/desbloquear)"
puts "- Todos os usuários já confirmados automaticamente para teste"
puts "="*80
