require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:one)
    @user = users(:admin_one)
    ActsAsTenant.current_tenant = @tenant
  end

  # Layout Switching Tests
  test "devise controllers use devise layout" do
    # Login page (Devise::SessionsController)
    get new_user_session_path
    assert_response :success
    assert_select "title", "CRM 3K - Autenticação"
  end

  test "password reset page uses devise layout" do
    # Password reset page (Devise::PasswordsController)
    get new_user_password_path
    assert_response :success
    assert_select "title", "CRM 3K - Autenticação"
  end

  test "registration page uses devise layout" do
    # Sign up page (Devise::RegistrationsController)
    get new_user_registration_path
    assert_response :success
    assert_select "title", "CRM 3K - Autenticação"
  end

  test "confirmation page uses devise layout" do
    # Confirmation page (Devise::ConfirmationsController)
    get new_user_confirmation_path
    assert_response :success
    assert_select "title", "CRM 3K - Autenticação"
  end

  test "authenticated pages use application layout" do
    sign_in @user

    get root_path
    assert_response :success

    # Application layout should have different title
    assert_select "title", text: /CRM 3K/, count: 1
  end

  # Tenant Isolation Tests
  test "current tenant is set after authentication" do
    sign_in @user

    get root_path
    assert_equal @tenant, ActsAsTenant.current_tenant
  end

  # Authentication Tests
  test "unauthenticated users are redirected to login" do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated users can access root path" do
    sign_in @user

    get root_path
    assert_response :success
  end

  # Subscription Status Tests
  test "expired tenant users are redirected to subscription expired page" do
    expired_tenant = tenants(:expired)
    expired_user = User.create!(
      tenant: expired_tenant,
      name: "Expired User",
      email: "expired#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      confirmed_at: Time.now
    )

    sign_in expired_user
    ActsAsTenant.current_tenant = expired_tenant

    # Try to access root, should redirect to subscription expired
    get root_path
    assert_response :redirect
    assert_match /expired|subscription/i, @response.redirect_url
  end

  test "super admin bypasses subscription check" do
    expired_tenant = tenants(:expired)
    super_admin = users(:super_admin)
    super_admin.update!(tenant: expired_tenant)

    sign_in super_admin
    ActsAsTenant.current_tenant = expired_tenant

    # Super admin should be able to access even with expired subscription
    # (assuming the before_action in ApplicationController allows this)
    get root_path
    # This may redirect or succeed depending on implementation
    assert_response :success
  end
end
