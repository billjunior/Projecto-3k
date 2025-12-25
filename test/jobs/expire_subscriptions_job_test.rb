require "test_helper"

class ExpireSubscriptionsJobTest < ActiveJob::TestCase
  setup do
    @tenant = tenants(:one)
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 30.days.from_now
    )
  end

  test "expires overdue subscriptions" do
    # Create tenant with expired subscription
    expired_tenant = Tenant.create!(
      name: "Expired Company",
      subdomain: "expired#{SecureRandom.hex(4)}",
      status: :active,
      subscription_status: 'active',
      subscription_expires_at: 1.day.ago
    )

    # Perform job
    ExpireSubscriptionsJob.perform_now

    # Verify status changed to expired
    expired_tenant.reload
    assert_equal 'expired', expired_tenant.subscription_status
  end

  test "does not expire subscriptions with future expiration date" do
    # Tenant with future expiration should remain active
    ExpireSubscriptionsJob.perform_now

    @tenant.reload
    assert_equal 'active', @tenant.subscription_status
  end

  test "sends expiration notification emails" do
    # Create tenant with expired subscription
    expired_tenant = Tenant.create!(
      name: "Expired Company",
      subdomain: "expired#{SecureRandom.hex(4)}",
      status: :active,
      subscription_status: 'active',
      subscription_expires_at: 1.day.ago
    )

    # Create admin user for the tenant
    User.create!(
      tenant: expired_tenant,
      name: "Admin User",
      email: "admin#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      admin: true,
      confirmed_at: Time.now
    )

    # Assert email is queued
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      ExpireSubscriptionsJob.perform_now
    end
  end

  test "sends expiring soon notifications for 7 days threshold" do
    # Create tenant expiring in exactly 7 days
    expiring_tenant = Tenant.create!(
      name: "Expiring Soon",
      subdomain: "expiring#{SecureRandom.hex(4)}",
      status: :active,
      subscription_status: 'active',
      subscription_expires_at: 7.days.from_now.beginning_of_day + 12.hours
    )

    # Create admin user
    User.create!(
      tenant: expiring_tenant,
      name: "Admin User",
      email: "admin#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      admin: true,
      confirmed_at: Time.now
    )

    # Should send notification for 7-day threshold
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      ExpireSubscriptionsJob.perform_now
    end
  end

  test "sends expiring soon notifications for 3 days threshold" do
    # Create tenant expiring in exactly 3 days
    expiring_tenant = Tenant.create!(
      name: "Expiring Very Soon",
      subdomain: "expiring3#{SecureRandom.hex(4)}",
      status: :active,
      subscription_status: 'active',
      subscription_expires_at: 3.days.from_now.beginning_of_day + 12.hours
    )

    # Create admin user
    User.create!(
      tenant: expiring_tenant,
      name: "Admin User",
      email: "admin#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      admin: true,
      confirmed_at: Time.now
    )

    # Should send notification for 3-day threshold
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      ExpireSubscriptionsJob.perform_now
    end
  end

  test "sends expiring soon notifications for 1 day threshold" do
    # Create tenant expiring tomorrow
    expiring_tenant = Tenant.create!(
      name: "Expiring Tomorrow",
      subdomain: "expiring1#{SecureRandom.hex(4)}",
      status: :active,
      subscription_status: 'active',
      subscription_expires_at: 1.day.from_now.beginning_of_day + 12.hours
    )

    # Create admin user
    User.create!(
      tenant: expiring_tenant,
      name: "Admin User",
      email: "admin#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      admin: true,
      confirmed_at: Time.now
    )

    # Should send notification for 1-day threshold
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      ExpireSubscriptionsJob.perform_now
    end
  end

  test "does not expire trial subscriptions with future expiration" do
    trial_tenant = Tenant.create!(
      name: "Trial Company",
      subdomain: "trial#{SecureRandom.hex(4)}",
      status: :active,
      subscription_status: 'trial',
      subscription_expires_at: 15.days.from_now
    )

    ExpireSubscriptionsJob.perform_now

    trial_tenant.reload
    assert_equal 'trial', trial_tenant.subscription_status
  end

  test "expires trial subscriptions that are overdue" do
    trial_tenant = Tenant.create!(
      name: "Expired Trial",
      subdomain: "trial_exp#{SecureRandom.hex(4)}",
      status: :active,
      subscription_status: 'trial',
      subscription_expires_at: 1.day.ago
    )

    ExpireSubscriptionsJob.perform_now

    trial_tenant.reload
    assert_equal 'expired', trial_tenant.subscription_status
  end

  test "does not process already expired subscriptions" do
    already_expired = Tenant.create!(
      name: "Already Expired",
      subdomain: "already#{SecureRandom.hex(4)}",
      status: :expired,
      subscription_status: 'expired',
      subscription_expires_at: 5.days.ago
    )

    # Should not change status (already expired)
    ExpireSubscriptionsJob.perform_now

    already_expired.reload
    assert_equal 'expired', already_expired.subscription_status
  end

  test "does not process suspended subscriptions" do
    suspended_tenant = Tenant.create!(
      name: "Suspended Company",
      subdomain: "suspended#{SecureRandom.hex(4)}",
      status: :suspended,
      subscription_status: 'suspended',
      subscription_expires_at: 1.day.ago
    )

    # Should not change status (suspended is handled manually)
    ExpireSubscriptionsJob.perform_now

    suspended_tenant.reload
    assert_equal 'suspended', suspended_tenant.subscription_status
  end
end
