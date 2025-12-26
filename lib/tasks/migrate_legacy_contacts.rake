namespace :contacts do
  desc "Migrate legacy contact data from Customers and Leads to Contact model"
  task migrate_legacy: :environment do
    puts "Starting legacy contact migration..."
    puts "=" * 80

    migrated_customers = 0
    migrated_leads = 0
    skipped_customers = 0
    skipped_leads = 0
    errors = []

    # Migrate Customer contacts
    puts "\n1. Migrating Customer contacts..."
    Customer.find_each do |customer|
      # Skip if already has contacts (idempotency)
      if customer.contacts.any?
        skipped_customers += 1
        next
      end

      begin
        # Create contact from customer data
        contact = customer.contacts.create!(
          tenant: customer.tenant,
          name: customer.name,
          email: customer.email,
          phone: customer.phone,
          whatsapp: customer.whatsapp,
          primary: true,
          notes: "Contacto migrado automaticamente de dados legacy"
        )
        migrated_customers += 1
        print "."
      rescue => e
        errors << "Customer ##{customer.id}: #{e.message}"
        print "F"
      end
    end

    puts "\n  ✓ Migrated: #{migrated_customers} customers"
    puts "  - Skipped: #{skipped_customers} customers (already have contacts)"

    # Migrate Lead contacts
    puts "\n2. Migrating Lead contacts..."
    Lead.find_each do |lead|
      # Skip if already has contacts or is converted (idempotency)
      if lead.contacts.any? || lead.converted?
        skipped_leads += 1
        next
      end

      begin
        # Create contact from lead data
        contact = lead.contacts.create!(
          tenant: lead.tenant,
          name: lead.name,
          email: lead.email,
          phone: lead.phone,
          primary: true,
          notes: "Contacto migrado automaticamente de dados legacy"
        )
        migrated_leads += 1
        print "."
      rescue => e
        errors << "Lead ##{lead.id}: #{e.message}"
        print "F"
      end
    end

    puts "\n  ✓ Migrated: #{migrated_leads} leads"
    puts "  - Skipped: #{skipped_leads} leads (already have contacts or converted)"

    # Summary
    puts "\n" + "=" * 80
    puts "MIGRATION SUMMARY:"
    puts "  Total migrated: #{migrated_customers + migrated_leads}"
    puts "    - Customers: #{migrated_customers}"
    puts "    - Leads: #{migrated_leads}"
    puts "  Total skipped: #{skipped_customers + skipped_leads}"
    puts "  Total contacts created: #{Contact.count}"

    if errors.any?
      puts "\n⚠️  ERRORS (#{errors.count}):"
      errors.each { |error| puts "  - #{error}" }
    else
      puts "\n✓ Migration completed successfully with no errors!"
    end

    puts "=" * 80
  end

  desc "Rollback legacy contact migration (removes all migrated contacts)"
  task rollback_migration: :environment do
    puts "⚠️  WARNING: This will delete all contacts with legacy migration notes!"
    print "Are you sure? (yes/no): "

    confirmation = STDIN.gets.chomp
    unless confirmation.downcase == 'yes'
      puts "Rollback cancelled."
      exit
    end

    count = Contact.where("notes LIKE ?", "%Contacto migrado automaticamente de dados legacy%").count
    Contact.where("notes LIKE ?", "%Contacto migrado automaticamente de dados legacy%").destroy_all

    puts "✓ Deleted #{count} migrated contacts."
  end

  desc "Show migration statistics"
  task migration_stats: :environment do
    puts "CONTACT MIGRATION STATISTICS:"
    puts "=" * 80
    puts "Total Contacts: #{Contact.count}"
    puts "  - Primary contacts: #{Contact.primary_contacts.count}"
    puts "  - Secondary contacts: #{Contact.secondary_contacts.count}"
    puts ""
    puts "Customers with contacts: #{Customer.joins(:contacts).distinct.count} / #{Customer.count}"
    puts "Leads with contacts: #{Lead.joins(:contacts).distinct.count} / #{Lead.count}"
    puts "  - Converted leads: #{Lead.converted.count}"
    puts "  - Unconverted leads: #{Lead.not_converted.count}"
    puts ""
    puts "Average contacts per customer: #{(Customer.joins(:contacts).count.to_f / Customer.joins(:contacts).distinct.count).round(2)}"
    puts "=" * 80
  end
end
