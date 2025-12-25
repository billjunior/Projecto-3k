namespace :subscription do
  desc "Configurar ambiente de teste de subscrições"
  task setup_test: :environment do
    puts "\n=== Configurando ambiente de teste de subscrições ===\n\n"

    # 1. Tornar primeiro usuário super admin
    user = User.first
    if user
      user.update!(super_admin: true, admin: true)
      puts "✅ Usuário '#{user.email}' agora é Super Admin"
    else
      puts "❌ Nenhum usuário encontrado. Crie um usuário primeiro."
      exit
    end

    # 2. Mostrar status atual dos tenants
    puts "\n📊 Status atual dos tenants:\n"
    Tenant.all.each do |tenant|
      puts "  • #{tenant.name}"
      puts "    - Status: #{tenant.subscription_status}"
      puts "    - Expira em: #{tenant.subscription_expires_at&.strftime('%d/%m/%Y %H:%M') || 'Não definido'}"
      puts "    - Dias restantes: #{tenant.days_remaining}"
      puts "    - Pode acessar: #{tenant.can_access? ? 'Sim ✅' : 'Não ❌'}"
      puts ""
    end

    puts "\n🔗 URLs importantes:"
    puts "  • Painel Admin: http://localhost:3000/admin/subscriptions"
    puts "  • Tela de expiração: http://localhost:3000/subscription/expired"
    puts ""
    puts "👤 Login com: #{user.email}"
    puts ""
  end

  desc "Simular expiração de subscrição (para teste)"
  task expire_current_tenant: :environment do
    tenant = Tenant.first
    tenant.update!(
      subscription_status: 'expired',
      subscription_expires_at: 1.day.ago
    )
    puts "✅ Subscrição do tenant '#{tenant.name}' foi expirada para teste"
    puts "   Tente acessar o sistema agora e você verá a tela de expiração"
  end

  desc "Renovar subscrição do tenant atual (após teste)"
  task renew_current_tenant: :environment do
    tenant = Tenant.first
    tenant.renew_subscription!(1)  # 1 mês
    puts "✅ Subscrição do tenant '#{tenant.name}' renovada por 1 mês"
    puts "   Nova data de expiração: #{tenant.subscription_expires_at.strftime('%d/%m/%Y')}"
  end

  desc "Executar job de expiração manualmente"
  task run_job: :environment do
    puts "🚀 Executando ExpireSubscriptionsJob...\n"
    ExpireSubscriptionsJob.perform_now
    puts "\n✅ Job executado com sucesso!"
  end

  desc "Ver informações detalhadas de um tenant"
  task :info, [:tenant_id] => :environment do |t, args|
    tenant_id = args[:tenant_id] || Tenant.first.id
    tenant = Tenant.find(tenant_id)

    puts "\n📋 Informações do Tenant: #{tenant.name}\n"
    puts "  ID: #{tenant.id}"
    puts "  Subdomínio: #{tenant.subdomain}"
    puts "  Status: #{tenant.subscription_status}"
    puts "  Plano: #{tenant.plan_name}"
    puts "  Expira em: #{tenant.subscription_expires_at&.strftime('%d/%m/%Y às %H:%M') || 'Não definido'}"
    puts "  Dias restantes: #{tenant.days_remaining}"
    puts "  Último pagamento: #{tenant.last_payment_date&.strftime('%d/%m/%Y') || 'Nunca'}"
    puts "  Pode acessar: #{tenant.can_access? ? 'Sim ✅' : 'Não ❌'}"
    puts "  Em trial: #{tenant.in_trial? ? 'Sim' : 'Não'}"
    puts "  Expirando em breve: #{tenant.expiring_soon? ? 'Sim ⚠️' : 'Não'}"
    puts ""
  end
end
