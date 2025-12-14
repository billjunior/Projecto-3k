require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:one)
    @user = users(:admin_one)
    @unconfirmed_user = users(:unconfirmed_user)
    ActsAsTenant.current_tenant = @tenant
  end

  # Login Tests
  test "user can login with valid credentials" do
    get new_user_session_path
    assert_response :success
    assert_select "h2", "CRM 3K"

    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "user cannot login with invalid password" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "wrongpassword"
      }
    }

    assert_response :success  # Renders login page again
    assert_select "div.alert", /Email ou senha inválidos/
  end

  test "user cannot login with non-existent email" do
    post user_session_path, params: {
      user: {
        email: "nonexistent@example.com",
        password: "password123"
      }
    }

    assert_response :success
    assert_select "div.alert", /Email ou senha inválidos/
  end

  test "unconfirmed user cannot login" do
    post user_session_path, params: {
      user: {
        email: @unconfirmed_user.email,
        password: "password123"
      }
    }

    assert_response :success
    assert_select "div.alert", /confirmar/
  end

  # Logout Tests
  test "logged in user can logout" do
    sign_in @user

    delete destroy_user_session_path
    assert_redirected_to root_path

    follow_redirect!
    assert_redirected_to new_user_session_path
  end

  # Password Reset Tests
  test "user can request password reset" do
    get new_user_password_path
    assert_response :success
    assert_select "h2", "Recuperar Senha"

    assert_emails 1 do
      post user_password_path, params: {
        user: {
          email: @user.email
        }
      }
    end

    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_select "div.notice", /instruções.*enviadas/i
  end

  test "password reset email contains reset link" do
    post user_password_path, params: {
      user: {
        email: @user.email
      }
    }

    email = ActionMailer::Base.deliveries.last
    assert_equal [@user.email], email.to
    assert_match /Redefinição de Senha/, email.subject
    assert_match /Redefinir Minha Senha/, email.body.to_s
  end

  test "user can reset password with valid token" do
    # Generate reset token
    raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
    @user.reset_password_token = hashed_token
    @user.reset_password_sent_at = Time.now
    @user.save!

    # Visit reset password page
    get edit_user_password_path(reset_password_token: raw_token)
    assert_response :success
    assert_select "h2", "Nova Senha"

    # Submit new password
    patch user_password_path, params: {
      user: {
        reset_password_token: raw_token,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }

    assert_redirected_to root_path
    @user.reload
    assert @user.valid_password?("newpassword123")
  end

  test "password reset fails with mismatched passwords" do
    raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
    @user.reset_password_token = hashed_token
    @user.reset_password_sent_at = Time.now
    @user.save!

    patch user_password_path, params: {
      user: {
        reset_password_token: raw_token,
        password: "newpassword123",
        password_confirmation: "differentpassword"
      }
    }

    assert_response :success
    assert_select "div.alert", /não.*confirmação/i
  end

  # Account Confirmation Tests
  test "user can resend confirmation instructions" do
    get new_user_confirmation_path
    assert_response :success
    assert_select "h2", "Reenviar Confirmação"

    assert_emails 1 do
      post user_confirmation_path, params: {
        user: {
          email: @unconfirmed_user.email
        }
      }
    end

    assert_redirected_to new_user_session_path
  end

  test "confirmation email contains confirmation link" do
    post user_confirmation_path, params: {
      user: {
        email: @unconfirmed_user.email
      }
    }

    email = ActionMailer::Base.deliveries.last
    assert_equal [@unconfirmed_user.email], email.to
    assert_match /Confirmar/, email.subject
    assert_match /Confirmar Minha Conta/, email.body.to_s
  end

  # Remember Me Tests
  test "user session persists with remember_me" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123",
        remember_me: "1"
      }
    }

    assert_not_nil cookies["remember_user_token"]
  end

  test "user session does not persist without remember_me" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123",
        remember_me: "0"
      }
    }

    assert_nil cookies.signed["remember_user_token"]
  end

  # Session Management Tests
  test "authenticated user can access protected pages" do
    sign_in @user

    get root_path
    assert_response :success
  end

  test "unauthenticated user is redirected to login" do
    get root_path
    assert_redirected_to new_user_session_path
  end

  # Layout Tests
  test "login page uses devise layout" do
    get new_user_session_path
    assert_response :success
    # Devise layout should not have navbar
    assert_select "nav.navbar", count: 0
    # Should have login card
    assert_select "div.login-card"
  end

  test "password reset page uses devise layout" do
    get new_user_password_path
    assert_response :success
    assert_select "nav.navbar", count: 0
    assert_select "div.password-reset-card"
  end

  test "authenticated pages use application layout" do
    sign_in @user
    get root_path
    assert_response :success
    # Application layout should have navbar
    assert_select "nav.navbar"
  end

  # Multi-tenancy Tests
  test "user cannot login to different tenant" do
    other_tenant = tenants(:two)
    other_user = users(:admin_two)

    ActsAsTenant.current_tenant = @tenant

    post user_session_path, params: {
      user: {
        email: other_user.email,
        password: "password123"
      }
    }

    # Should fail because user belongs to different tenant
    assert_response :success
    assert_select "div.alert"
  end

  test "user from expired tenant cannot login" do
    expired_tenant = tenants(:expired)
    ActsAsTenant.current_tenant = expired_tenant

    # Create a user for expired tenant
    expired_user = User.create!(
      tenant: expired_tenant,
      name: "Expired User",
      email: "expired@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      confirmed_at: Time.now
    )

    post user_session_path, params: {
      user: {
        email: expired_user.email,
        password: "password123"
      }
    }

    # Login succeeds but should be redirected to subscription expired page
    follow_redirect!
    assert_match /expired|expirada/i, request.fullpath
  end
end
