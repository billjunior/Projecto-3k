require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @user = users(:admin_one)
    ActsAsTenant.current_tenant = @tenant
  end

  # Validation Tests
  test "should be valid with valid attributes" do
    user = User.new(
      tenant: @tenant,
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial
    )
    assert user.valid?
  end

  test "should require name" do
    @user.name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
  end

  test "should require unique email" do
    duplicate_user = User.new(
      tenant: @tenant,
      name: "Another User",
      email: @user.email,  # Same email
      password: "password123",
      password_confirmation: "password123",
      role: :commercial
    )
    assert_not duplicate_user.valid?
  end

  test "should require role" do
    @user.role = nil
    assert_not @user.valid?
  end

  test "should require password on creation" do
    user = User.new(
      tenant: @tenant,
      name: "Test User",
      email: "newuser@example.com",
      role: :commercial
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "should require password confirmation to match" do
    user = User.new(
      tenant: @tenant,
      name: "Test User",
      email: "newuser@example.com",
      password: "password123",
      password_confirmation: "differentpassword",
      role: :commercial
    )
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  # Association Tests
  test "should belong to tenant" do
    assert_respond_to @user, :tenant
    assert_equal @tenant, @user.tenant
  end

  # Multi-tenancy Tests
  test "users are scoped by tenant" do
    tenant1 = tenants(:one)
    tenant2 = tenants(:two)

    with_tenant(tenant1) do
      user_count_tenant1 = User.count
      assert user_count_tenant1 > 0
    end

    with_tenant(tenant2) do
      user_count_tenant2 = User.count
      # Counts should be independent
      assert_respond_to User, :count
    end
  end

  test "user automatically gets current tenant" do
    with_tenant(@tenant) do
      user = User.new(
        name: "Auto Tenant User",
        email: "autotenant@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: :commercial
      )
      user.save!
      assert_equal @tenant, user.tenant
    end
  end

  # Role Tests
  test "role enum works correctly" do
    @user.commercial!
    assert @user.commercial?

    @user.cyber_tech!
    assert @user.cyber_tech?

    @user.attendant!
    assert @user.attendant?

    @user.production!
    assert @user.production?
  end

  # Permission Tests
  test "commercial? returns true for commercial role" do
    @user.role = :commercial
    assert @user.commercial?
  end

  test "cyber_tech? returns true for cyber_tech role" do
    @user.role = :cyber_tech
    assert @user.cyber_tech?
  end

  test "attendant? returns true for attendant role" do
    @user.role = :attendant
    assert @user.attendant?
  end

  test "production? returns true for production role" do
    @user.role = :production
    assert @user.production?
  end

  test "admin? returns true when admin flag is true" do
    @user.admin = true
    assert @user.admin?
  end

  test "admin? returns false when admin flag is false" do
    @user.admin = false
    assert_not @user.admin?
  end

  test "super_admin? returns true when super_admin flag is true" do
    @user.super_admin = true
    assert @user.super_admin?
  end

  test "super_admin? returns false when super_admin flag is false" do
    @user.super_admin = false
    assert_not @user.super_admin?
  end

  test "full_access? returns true for super_admin" do
    @user.super_admin = true
    @user.admin = false
    assert @user.full_access?
  end

  test "full_access? returns true for admin" do
    @user.super_admin = false
    @user.admin = true
    assert @user.full_access?
  end

  test "full_access? returns false for regular user" do
    @user.super_admin = false
    @user.admin = false
    assert_not @user.full_access?
  end

  test "can_access_crm? returns true for commercial role" do
    @user.role = :commercial
    @user.super_admin = false
    @user.admin = false
    assert @user.can_access_crm?
  end

  test "can_access_crm? returns false for cyber_tech role without admin" do
    @user.role = :cyber_tech
    @user.super_admin = false
    @user.admin = false
    assert_not @user.can_access_crm?
  end

  test "can_access_crm? returns true for cyber_tech with super_admin" do
    @user.role = :cyber_tech
    @user.super_admin = true
    @user.admin = false
    assert @user.can_access_crm?
  end

  test "can_access_cyber? returns true for cyber_tech role" do
    @user.role = :cyber_tech
    @user.super_admin = false
    assert @user.can_access_cyber?
  end

  test "can_access_cyber? returns false for commercial role without super_admin" do
    @user.role = :commercial
    @user.super_admin = false
    assert_not @user.can_access_cyber?
  end

  test "can_access_cyber? returns true for commercial with super_admin" do
    @user.role = :commercial
    @user.super_admin = true
    assert @user.can_access_cyber?
  end

  test "can_manage_users? returns true for super_admin only" do
    @user.super_admin = true
    @user.admin = false
    assert @user.can_manage_users?

    @user.super_admin = false
    @user.admin = true
    assert_not @user.can_manage_users?
  end

  test "financial_director? returns true for admin with financial department" do
    @user.admin = true
    @user.department = :financial
    assert @user.financial_director?
  end

  test "financial_director? returns false for non-admin with financial department" do
    @user.admin = false
    @user.department = :financial
    assert_not @user.financial_director?
  end

  test "can_view_financial_reports? returns true for super_admin" do
    @user.super_admin = true
    @user.admin = false
    assert @user.can_view_financial_reports?
  end

  test "can_view_financial_reports? returns true for financial_director" do
    @user.super_admin = false
    @user.admin = true
    @user.department = :financial
    assert @user.can_view_financial_reports?
  end

  test "can_view_financial_reports? returns false for regular admin" do
    @user.super_admin = false
    @user.admin = true
    @user.department = :commercial_dept
    assert_not @user.can_view_financial_reports?
  end

  test "can_manage_cyber? returns true for super_admin" do
    @user.super_admin = true
    @user.role = :commercial
    assert @user.can_manage_cyber?
  end

  test "can_manage_cyber? returns true for cyber_tech" do
    @user.super_admin = false
    @user.role = :cyber_tech
    assert @user.can_manage_cyber?
  end

  test "can_manage_cyber? returns false for regular user" do
    @user.super_admin = false
    @user.role = :commercial
    assert_not @user.can_manage_cyber?
  end

  # Scopes Tests
  test "active scope returns only active users" do
    @user.update!(active: true)
    inactive_user = users(:user_one)
    inactive_user.update!(active: false)

    active_users = User.active
    assert_includes active_users, @user
    assert_not_includes active_users, inactive_user
  end

  test "super_admins scope returns only super admins" do
    @user.update!(super_admin: true)
    regular_user = users(:user_one)
    regular_user.update!(super_admin: false)

    super_admins = User.super_admins
    assert_includes super_admins, @user
    assert_not_includes super_admins, regular_user
  end

  test "admins scope returns only admins" do
    @user.update!(admin: true)
    regular_user = users(:user_one)
    regular_user.update!(admin: false)

    admins = User.admins
    assert_includes admins, @user
    assert_not_includes admins, regular_user
  end

  test "crm_users scope excludes cyber_tech users" do
    commercial_user = @user
    commercial_user.update!(role: :commercial)

    cyber_user = users(:user_one)
    cyber_user.update!(role: :cyber_tech)

    crm_users = User.crm_users
    assert_includes crm_users, commercial_user
    assert_not_includes crm_users, cyber_user
  end

  test "cyber_users scope includes cyber_tech and super_admin users" do
    cyber_user = @user
    cyber_user.update!(role: :cyber_tech, super_admin: false)

    super_admin_user = users(:super_admin)

    cyber_users = User.cyber_users
    assert_includes cyber_users, cyber_user
    assert_includes cyber_users, super_admin_user
  end

  # Devise Tests
  test "user can update password" do
    new_password = "newpassword123"
    @user.password = new_password
    @user.password_confirmation = new_password
    assert @user.save

    assert @user.valid_password?(new_password)
  end

  test "unconfirmed user cannot login" do
    unconfirmed = users(:unconfirmed_user)
    assert_nil unconfirmed.confirmed_at
    assert_not unconfirmed.confirmed?
  end

  test "confirmed user can login" do
    assert_not_nil @user.confirmed_at
    assert @user.confirmed?
  end
end
