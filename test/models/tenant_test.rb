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
end
