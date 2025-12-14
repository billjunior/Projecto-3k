namespace :lan_sessions do
  desc "Enviar relatórios mensais de sessões LAN para todos os tenants"
  task send_monthly_reports: :environment do
    puts "Iniciando envio de relatórios mensais de sessões LAN..."

    # Get previous month
    last_month = Date.today.last_month
    month = last_month.month
    year = last_month.year

    puts "Gerando relatórios para #{Date::MONTHNAMES[month]} de #{year}"

    # Process each tenant
    Tenant.where(status: :active).find_each do |tenant|
      puts "  Processando tenant: #{tenant.name}"

      ActsAsTenant.with_tenant(tenant) do
        # Get admin users emails from this tenant
        admin_emails = User.where(active: true)
                          .where("email IS NOT NULL AND email != ''")
                          .pluck(:email)

        if admin_emails.any?
          # Get admin email (first admin user)
          recipient_email = admin_emails.first

          # Check if there are sessions in the period
          sessions_count = LanSession.where(
            'EXTRACT(MONTH FROM start_time) = ? AND EXTRACT(YEAR FROM start_time) = ?',
            month,
            year
          ).count

          if sessions_count > 0
            begin
              # Send report
              LanSessionReportMailer.monthly_report(
                tenant,
                month,
                year,
                recipient_email
              ).deliver_now

              puts "    ✓ Relatório enviado para #{recipient_email} (#{sessions_count} sessões)"
            rescue => e
              puts "    ✗ Erro ao enviar para #{recipient_email}: #{e.message}"
            end
          else
            puts "    → Nenhuma sessão no período, relatório não enviado"
          end
        else
          puts "    ✗ Nenhum email de administrador encontrado"
        end
      end
    end

    puts "Processo concluído!"
  end

  desc "Testar envio de relatório mensal (mês atual)"
  task test_report: :environment do
    puts "Testando envio de relatório..."

    month = Date.today.month
    year = Date.today.year

    tenant = Tenant.first

    unless tenant
      puts "Nenhum tenant encontrado!"
      exit
    end

    puts "Tenant: #{tenant.name}"
    puts "Período: #{Date::MONTHNAMES[month]} de #{year}"

    ActsAsTenant.with_tenant(tenant) do
      recipient_email = User.where(active: true).first&.email

      unless recipient_email
        puts "Nenhum usuário ativo encontrado!"
        exit
      end

      puts "Enviando para: #{recipient_email}"

      begin
        LanSessionReportMailer.monthly_report(
          tenant,
          month,
          year,
          recipient_email
        ).deliver_now

        puts "✓ Relatório de teste enviado com sucesso!"
      rescue => e
        puts "✗ Erro: #{e.message}"
        puts e.backtrace.first(5)
      end
    end
  end
end
