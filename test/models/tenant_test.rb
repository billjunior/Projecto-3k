require "test_helper"

class TenantTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
  end

  # Validation Tests
  test "should be valid with valid attributes" do
    tenant = Tenant.new(
      name: "Test Company",
      subdomain: "testcompany",
      status: :active,
      subscription_start: Date.today,
      subscription_end: 30.days.from_now.to_date
    )
    assert tenant.valid?
  end

  test "should require name" do
    @tenant.name = nil
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:name], "can't be blank"
  end

  test "should require subdomain" do
    @tenant.subdomain = nil
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:subdomain], "can't be blank"
  end

  test "should require unique subdomain" do
    duplicate_tenant = Tenant.new(
      name: "Another Company",
      subdomain: @tenant.subdomain,  # Same subdomain
      status: :active
    )
    assert_not duplicate_tenant.valid?
    assert_includes duplicate_tenant.errors[:subdomain], "has already been taken"
  end

  test "should require status" do
    @tenant.status = nil
    assert_not @tenant.valid?
  end

  # Association Tests
  test "should have many users" do
    assert_respond_to @tenant, :users
  end

  test "should destroy users when tenant is destroyed" do
    tenant = Tenant.create!(name: "Test", subdomain: "test#{SecureRandom.hex(4)}", status: :active)
    user = User.create!(
      tenant: tenant,
      name: "Test User",
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      confirmed_at: Time.now
    )

    assert_difference 'User.count', -1 do
      tenant.destroy
    end
  end

  # Subscription Status Tests
  test "active? returns true for active tenant with future subscription_end" do
    @tenant.status = :active
    @tenant.subscription_end = 30.days.from_now.to_date
    @tenant.save!

    assert @tenant.active?
  end

  test "active? returns true for active tenant with nil subscription_end" do
    @tenant.status = :active
    @tenant.subscription_end = nil
    @tenant.save!

    assert @tenant.active?
  end

  test "active? returns false for expired status" do
    @tenant.status = :expired
    @tenant.subscription_end = 30.days.from_now.to_date
    @tenant.save!

    assert_not @tenant.active?
  end

  test "active? returns false for active tenant with past subscription_end" do
    @tenant.status = :active
    @tenant.subscription_end = 5.days.ago.to_date
    @tenant.save!

    assert_not @tenant.active?
  end

  test "expired? returns true when subscription_end is in the past" do
    @tenant.subscription_end = 5.days.ago.to_date
    @tenant.save!

    assert @tenant.expired?
  end

  test "expired? returns false when subscription_end is in the future" do
    @tenant.subscription_end = 30.days.from_now.to_date
    @tenant.save!

    assert_not @tenant.expired?
  end

  test "expired? returns false when subscription_end is nil" do
    @tenant.subscription_end = nil
    @tenant.save!

    assert_not @tenant.expired?
  end

  # Days Until Expiration Tests
  test "days_until_expiration returns correct number of days" do
    @tenant.subscription_end = 10.days.from_now.to_date
    @tenant.save!

    assert_equal 10, @tenant.days_until_expiration
  end

  test "days_until_expiration returns negative number for expired subscription" do
    @tenant.subscription_end = 5.days.ago.to_date
    @tenant.save!

    assert_equal(-5, @tenant.days_until_expiration)
  end

  test "days_until_expiration returns nil when subscription_end is nil" do
    @tenant.subscription_end = nil
    @tenant.save!

    assert_nil @tenant.days_until_expiration
  end

  # Expiring Soon Tests
  test "expiring_soon? returns true for subscription expiring in 10 days" do
    @tenant.subscription_end = 10.days.from_now.to_date
    @tenant.save!

    assert @tenant.expiring_soon?
  end

  test "expiring_soon? returns true for subscription expiring in 15 days" do
    @tenant.subscription_end = 15.days.from_now.to_date
    @tenant.save!

    assert @tenant.expiring_soon?
  end

  test "expiring_soon? returns false for subscription expiring in 20 days" do
    @tenant.subscription_end = 20.days.from_now.to_date
    @tenant.save!

    assert_not @tenant.expiring_soon?
  end

  test "expiring_soon? returns false for expired subscription" do
    @tenant.subscription_end = 5.days.ago.to_date
    @tenant.save!

    assert_not @tenant.expiring_soon?
  end

  test "expiring_soon? returns false when subscription_end is nil" do
    @tenant.subscription_end = nil
    @tenant.save!

    assert_not @tenant.expiring_soon?
  end

  # Scopes Tests
  test "active_subscriptions scope returns only active tenants" do
    active_tenants = Tenant.active_subscriptions
    assert active_tenants.all? { |t| t.status == 'active' }
  end

  test "expired_subscriptions scope returns only expired tenants" do
    expired_tenants = Tenant.expired_subscriptions
    assert expired_tenants.all? { |t| t.status == 'expired' }
  end

  test "expiring_soon scope returns tenants expiring within 15 days" do
    # Create tenant expiring in 10 days
    soon_tenant = Tenant.create!(
      name: "Expiring Soon",
      subdomain: "expiring#{SecureRandom.hex(4)}",
      status: :active,
      subscription_start: 20.days.ago.to_date,
      subscription_end: 10.days.from_now.to_date
    )

    expiring_tenants = Tenant.expiring_soon
    assert_includes expiring_tenants, soon_tenant
  end

  # Enum Tests
  test "status enum works correctly" do
    @tenant.active!
    assert @tenant.active?

    @tenant.expired!
    assert @tenant.expired?

    @tenant.suspended!
    assert @tenant.suspended?
  end

  # New Subscription Methods Tests
  test "subscription_active? returns true for active subscription with future expiration" do
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 30.days.from_now
    )
    assert @tenant.subscription_active?
  end

  test "subscription_active? returns false for expired subscription" do
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 1.day.ago
    )
    assert_not @tenant.subscription_active?
  end

  test "subscription_active? returns false when subscription_expires_at is nil" do
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: nil
    )
    assert_not @tenant.subscription_active?
  end

  test "in_trial? returns true for trial with future expiration" do
    @tenant.update!(
      subscription_status: 'trial',
      subscription_expires_at: 15.days.from_now
    )
    assert @tenant.in_trial?
  end

  test "in_trial? returns false for trial with past expiration" do
    @tenant.update!(
      subscription_status: 'trial',
      subscription_expires_at: 1.day.ago
    )
    assert_not @tenant.in_trial?
  end

  test "can_access? returns true for active subscription" do
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 30.days.from_now
    )
    assert @tenant.can_access?
  end

  test "can_access? returns true for trial subscription" do
    @tenant.update!(
      subscription_status: 'trial',
      subscription_expires_at: 15.days.from_now
    )
    assert @tenant.can_access?
  end

  test "can_access? returns false for suspended subscription" do
    @tenant.update!(
      subscription_status: 'suspended',
      subscription_expires_at: 30.days.from_now
    )
    assert_not @tenant.can_access?
  end

  test "can_access? returns false for expired subscription" do
    @tenant.update!(
      subscription_status: 'expired',
      subscription_expires_at: 1.day.ago
    )
    assert_not @tenant.can_access?
  end

  test "suspended? returns true when subscription_status is suspended" do
    @tenant.update!(subscription_status: 'suspended')
    assert @tenant.suspended?
  end

  test "days_remaining returns correct number of days" do
    @tenant.update!(subscription_expires_at: 10.days.from_now)
    # Allow for rounding (9-10 days is acceptable)
    assert_operator @tenant.days_remaining, :>=, 9
    assert_operator @tenant.days_remaining, :<=, 10
  end

  test "days_remaining returns negative for expired subscription" do
    @tenant.update!(subscription_expires_at: 5.days.ago)
    # Should be negative for expired subscriptions
    assert_operator @tenant.days_remaining, :<, 0
  end

  test "expiring_soon? with custom threshold" do
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 5.days.from_now
    )
    assert @tenant.expiring_soon?(7)
    assert_not @tenant.expiring_soon?(3)
  end

  test "renew_subscription! extends expiration when not expired" do
    original_expiration = 10.days.from_now
    @tenant.update!(
      subscription_status: 'trial',
      subscription_expires_at: original_expiration
    )

    @tenant.renew_subscription!(1)

    assert_equal 'active', @tenant.subscription_status
    assert @tenant.subscription_expires_at > original_expiration
    assert_not_nil @tenant.last_payment_date
  end

  test "renew_subscription! sets expiration from now when expired" do
    @tenant.update!(
      subscription_status: 'expired',
      subscription_expires_at: 5.days.ago
    )

    @tenant.renew_subscription!(2)

    assert_equal 'active', @tenant.subscription_status
    assert @tenant.subscription_expires_at > Time.current
  end

  test "expire_subscription! sets status to expired" do
    @tenant.update!(subscription_status: 'active')
    @tenant.expire_subscription!

    assert_equal 'expired', @tenant.subscription_status
  end

  test "suspend_subscription! sets status to suspended" do
    @tenant.update!(subscription_status: 'active')
    @tenant.suspend_subscription!

    assert_equal 'suspended', @tenant.subscription_status
  end

  test "activate_subscription! sets to active when not expired" do
    @tenant.update!(
      subscription_status: 'suspended',
      subscription_expires_at: 30.days.from_now
    )

    @tenant.activate_subscription!

    assert_equal 'active', @tenant.subscription_status
  end

  test "activate_subscription! sets to expired when past expiration" do
    @tenant.update!(
      subscription_status: 'suspended',
      subscription_expires_at: 5.days.ago
    )

    @tenant.activate_subscription!

    assert_equal 'expired', @tenant.subscription_status
  end

  test "plan_name returns formatted plan names" do
    @tenant.update!(subscription_plan: 'monthly')
    assert_equal 'Mensal', @tenant.plan_name

    @tenant.update!(subscription_plan: 'quarterly')
    assert_equal 'Trimestral', @tenant.plan_name

    @tenant.update!(subscription_plan: 'yearly')
    assert_equal 'Anual', @tenant.plan_name
  end

  test "subscription_badge_class returns correct CSS classes" do
    @tenant.update!(subscription_status: 'active')
    assert_equal 'bg-success', @tenant.subscription_badge_class

    @tenant.update!(subscription_status: 'trial')
    assert_equal 'bg-info', @tenant.subscription_badge_class

    @tenant.update!(subscription_status: 'expired')
    assert_equal 'bg-danger', @tenant.subscription_badge_class

    @tenant.update!(subscription_status: 'suspended')
    assert_equal 'bg-warning', @tenant.subscription_badge_class
  end
end
