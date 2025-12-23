namespace :missing_items do
  desc "Enviar relatórios semanais de itens em falta para todos os tenants"
  task send_weekly_reports: :environment do
    puts "Iniciando envio de relatórios semanais de itens em falta..."

    week_end = Date.today
    week_start = week_end - 7.days

    puts "Período: #{week_start} a #{week_end}"

    # Process each tenant
    Tenant.where(status: :active).find_each do |tenant|
      puts "  Processando tenant: #{tenant.name}"

      ActsAsTenant.with_tenant(tenant) do
        # Get configured recipients from company settings
        recipients = tenant.company_setting&.missing_items_recipients || []

        if recipients.empty?
          puts "    → Nenhum email configurado para notificações"
          next
        end

        # Count pending missing items
        missing_items_count = MissingItem.pending.count

        if missing_items_count > 0
          recipients.each do |email|
            begin
              # Send weekly summary
              MissingItemsMailer.weekly_summary(
                tenant,
                week_start,
                week_end,
                email
              ).deliver_now

              puts "    ✓ Relatório enviado para #{email} (#{missing_items_count} itens pendentes)"
            rescue => e
              puts "    ✗ Erro ao enviar para #{email}: #{e.message}"
            end
          end

          # Mark items as included in weekly report
          MissingItem.pending.update_all(included_in_weekly_report: true)
        else
          puts "    → Nenhum item em falta pendente, relatório não enviado"
        end
      end
    end

    puts "Processo concluído!"
  end

  desc "Testar envio de relatório semanal"
  task test_weekly_report: :environment do
    puts "Testando envio de relatório semanal..."

    week_end = Date.today
    week_start = week_end - 7.days

    tenant = Tenant.first

    unless tenant
      puts "Nenhum tenant encontrado!"
      exit
    end

    puts "Tenant: #{tenant.name}"
    puts "Período: #{week_start} a #{week_end}"

    ActsAsTenant.with_tenant(tenant) do
      # Get configured recipients
      recipients = tenant.company_setting&.missing_items_recipients

      if recipients.blank?
        puts "Nenhum email configurado! Usando email do primeiro usuário ativo..."
        recipient_email = User.where(active: true).first&.email

        unless recipient_email
          puts "Nenhum usuário ativo encontrado!"
          exit
        end

        recipients = [recipient_email]
      end

      recipients.each do |email|
        puts "Enviando para: #{email}"

        begin
          MissingItemsMailer.weekly_summary(
            tenant,
            week_start,
            week_end,
            email
          ).deliver_now

          puts "✓ Relatório de teste enviado com sucesso!"
        rescue => e
          puts "✗ Erro: #{e.message}"
          puts e.backtrace.first(5)
        end
      end
    end
  end
end
