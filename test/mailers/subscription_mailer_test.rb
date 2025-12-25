require "test_helper"

class SubscriptionMailerTest < ActionMailer::TestCase
  setup do
    @tenant = tenants(:one)
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 30.days.from_now
    )

    # Create admin user for testing
    @admin = User.create!(
      tenant: @tenant,
      name: "Admin User",
      email: "admin_test#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      admin: true,
      confirmed_at: Time.now
    )
  end

  test "expired_notification email" do
    @tenant.update!(subscription_status: 'expired')

    email = SubscriptionMailer.expired_notification(@tenant)

    # Check email headers
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      email.deliver_now
    end

    assert_equal [@admin.email], email.to
    assert_equal "Subscrição Expirada - #{@tenant.name} - CRM 3K", email.subject
    assert_match @tenant.name, email.body.encoded
  end

  test "expired_notification sends to all admins" do
    # Create another admin
    admin2 = User.create!(
      tenant: @tenant,
      name: "Admin User 2",
      email: "admin2_test#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      admin: true,
      confirmed_at: Time.now
    )

    @tenant.update!(subscription_status: 'expired')

    email = SubscriptionMailer.expired_notification(@tenant)

    # Should send to both admins
    assert_includes email.to, @admin.email
    assert_includes email.to, admin2.email
  end

  test "expired_notification sends to super_admins" do
    super_admin = User.create!(
      tenant: @tenant,
      name: "Super Admin",
      email: "super_admin#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      super_admin: true,
      confirmed_at: Time.now
    )

    @tenant.update!(subscription_status: 'expired')

    email = SubscriptionMailer.expired_notification(@tenant)

    assert_includes email.to, super_admin.email
  end

  test "expiring_soon_notification email" do
    @tenant.update!(subscription_expires_at: 7.days.from_now)

    email = SubscriptionMailer.expiring_soon_notification(@tenant)

    # Check email headers
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      email.deliver_now
    end

    assert_equal [@admin.email], email.to
    assert_match "Subscrição Expira em", email.subject
    assert_match @tenant.name, email.subject
    assert_match @tenant.name, email.body.encoded
  end

  test "expiring_soon_notification includes days_remaining" do
    @tenant.update!(subscription_expires_at: 5.days.from_now)

    email = SubscriptionMailer.expiring_soon_notification(@tenant)

    # Should include the number of days
    assert_match /5 Dias/, email.subject
    assert_match email.body.encoded, /5.*dias?/i
  end

  test "renewed_notification email" do
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 60.days.from_now,
      last_payment_date: Time.current
    )

    email = SubscriptionMailer.renewed_notification(@tenant)

    # Check email headers
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      email.deliver_now
    end

    assert_equal [@admin.email], email.to
    assert_equal "Subscrição Renovada com Sucesso - #{@tenant.name} - CRM 3K", email.subject
    assert_match @tenant.name, email.body.encoded
  end

  test "renewed_notification includes new expiration date" do
    new_expiration = 60.days.from_now
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: new_expiration,
      last_payment_date: Time.current
    )

    email = SubscriptionMailer.renewed_notification(@tenant)

    # Should mention renewal in body
    assert_match /renov/i, email.body.encoded
  end

  test "mailers include company_settings when available" do
    # Create company settings for tenant
    company_setting = CompanySetting.create!(
      tenant: @tenant,
      company_name: "Test Company Ltd",
      email: "contact@testcompany.com",
      phone: "+244 123 456 789"
    )

    email = SubscriptionMailer.expired_notification(@tenant)

    # Company info should be in email
    assert_match company_setting.company_name, email.body.encoded
  end

  test "mailers work without company_settings" do
    # Ensure tenant has no company settings
    @tenant.company_setting&.destroy

    # Should not raise error
    assert_nothing_raised do
      email = SubscriptionMailer.expired_notification(@tenant)
      email.deliver_now
    end
  end

  test "mailers do not send to non-admin users" do
    # Create commercial user (not admin)
    commercial = User.create!(
      tenant: @tenant,
      name: "Commercial User",
      email: "commercial#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      confirmed_at: Time.now
    )

    email = SubscriptionMailer.expired_notification(@tenant)

    # Should not include commercial user
    assert_not_includes email.to, commercial.email
    # Should still include admin
    assert_includes email.to, @admin.email
  end
end
