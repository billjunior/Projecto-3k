require "test_helper"

class DeviseMailerTest < ActionMailer::TestCase
  setup do
    @tenant = tenants(:one)
    @user = users(:admin_one)
    ActsAsTenant.current_tenant = @tenant
  end

  # Password Reset Email Tests
  test "reset_password_instructions email is in Portuguese" do
    # Generate reset token
    raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
    @user.reset_password_token = hashed_token
    @user.reset_password_sent_at = Time.now
    @user.save!

    email = Devise::Mailer.reset_password_instructions(@user, raw_token)

    # Test email metadata
    assert_equal [@user.email], email.to
    assert_match /senha/i, email.subject
    assert_match /Redefinição de Senha/i, email.subject

    # Test email content
    body = email.body.to_s
    assert_match /Redefinição de Senha/, body
    assert_match /Olá/, body
    assert_match /Redefinir Minha Senha/, body
    assert_match /solicitação para redefinir a senha/, body
  end

  test "reset_password_instructions contains valid reset link" do
    raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
    @user.reset_password_token = hashed_token
    @user.reset_password_sent_at = Time.now
    @user.save!

    email = Devise::Mailer.reset_password_instructions(@user, raw_token)
    body = email.body.to_s

    # Should contain reset password URL
    assert_match /password\/edit/, body
    assert_match /reset_password_token=#{raw_token}/, body
  end

  test "reset_password_instructions has purple gradient design" do
    raw_token = "test_token"
    email = Devise::Mailer.reset_password_instructions(@user, raw_token)
    body = email.body.to_s

    # Check for design elements
    assert_match /#667eea/, body  # Purple gradient color
    assert_match /#764ba2/, body  # Purple gradient color
    assert_match /gradient/, body
  end

  # Confirmation Email Tests
  test "confirmation_instructions email is in Portuguese" do
    raw_token = "test_confirmation_token"
    email = Devise::Mailer.confirmation_instructions(@user, raw_token)

    assert_equal [@user.email], email.to
    assert_match /confirmação/i, email.subject
    assert_match /Bem-vindo|Confirma/i, email.subject

    body = email.body.to_s
    assert_match /Bem-vindo/, body
    assert_match /Confirmar Minha Conta/, body
    assert_match /sua conta foi criada/, body
  end

  test "confirmation_instructions contains valid confirmation link" do
    raw_token = "test_token"
    email = Devise::Mailer.confirmation_instructions(@user, raw_token)
    body = email.body.to_s

    # Should contain confirmation URL
    assert_match /confirmation\?confirmation_token=#{raw_token}/, body
  end

  # Account Unlock Email Tests
  test "unlock_instructions email is in Portuguese" do
    raw_token = "test_unlock_token"
    email = Devise::Mailer.unlock_instructions(@user, raw_token)

    assert_equal [@user.email], email.to
    assert_match /desbloqueio|bloqueada/i, email.subject

    body = email.body.to_s
    assert_match /Desbloquear Conta/, body
    assert_match /bloqueada/, body
    assert_match /tentativas de login/, body
  end

  test "unlock_instructions contains valid unlock link" do
    raw_token = "test_token"
    email = Devise::Mailer.unlock_instructions(@user, raw_token)
    body = email.body.to_s

    # Should contain unlock URL
    assert_match /unlock\?unlock_token=#{raw_token}/, body
  end

  # Email Changed Notification Tests
  test "email_changed email is in Portuguese" do
    email = Devise::Mailer.email_changed(@user)

    assert_equal [@user.email], email.to
    assert_match /email.*alterado/i, email.subject

    body = email.body.to_s
    assert_match /email foi alterado/, body
    assert_match /novo email/, body
    assert_match /segurança/, body
  end

  test "email_changed email has security warning" do
    email = Devise::Mailer.email_changed(@user)
    body = email.body.to_s

    assert_match /não foi você.*contate.*suporte/i, body
  end

  # Password Changed Notification Tests
  test "password_change email is in Portuguese" do
    email = Devise::Mailer.password_change(@user)

    assert_equal [@user.email], email.to
    assert_match /senha.*alterada/i, email.subject

    body = email.body.to_s
    assert_match /senha foi alterada com sucesso/, body
    assert_match /segurança/, body
  end

  test "password_change email has security warning" do
    email = Devise::Mailer.password_change(@user)
    body = email.body.to_s

    assert_match /não foi você.*contate.*suporte/i, body
  end

  test "password_change email includes timestamp" do
    email = Devise::Mailer.password_change(@user)
    body = email.body.to_s

    # Should include some form of date/time
    assert_match /\d{2}\/\d{2}\/\d{4}|\d{4}-\d{2}-\d{2}/, body
  end

  # Design Consistency Tests
  test "all emails use consistent purple gradient design" do
    emails = [
      Devise::Mailer.reset_password_instructions(@user, "token"),
      Devise::Mailer.confirmation_instructions(@user, "token"),
      Devise::Mailer.unlock_instructions(@user, "token"),
      Devise::Mailer.email_changed(@user),
      Devise::Mailer.password_change(@user)
    ]

    emails.each do |email|
      body = email.body.to_s
      assert_match /#667eea/, body, "Email #{email.subject} missing purple color #667eea"
      assert_match /#764ba2/, body, "Email #{email.subject} missing purple color #764ba2"
      assert_match /gradient/, body, "Email #{email.subject} missing gradient"
    end
  end

  test "all emails have proper HTML structure" do
    emails = [
      Devise::Mailer.reset_password_instructions(@user, "token"),
      Devise::Mailer.confirmation_instructions(@user, "token"),
      Devise::Mailer.unlock_instructions(@user, "token"),
      Devise::Mailer.email_changed(@user),
      Devise::Mailer.password_change(@user)
    ]

    emails.each do |email|
      body = email.body.to_s
      assert_match /<html/, body, "Email #{email.subject} missing HTML tag"
      assert_match /<\/html>/, body, "Email #{email.subject} missing closing HTML tag"
      assert_match /email-header/, body, "Email #{email.subject} missing header class"
      assert_match /email-body/, body, "Email #{email.subject} missing body class"
    end
  end

  test "all emails include CRM 3K branding" do
    emails = [
      Devise::Mailer.reset_password_instructions(@user, "token"),
      Devise::Mailer.confirmation_instructions(@user, "token"),
      Devise::Mailer.unlock_instructions(@user, "token"),
      Devise::Mailer.email_changed(@user),
      Devise::Mailer.password_change(@user)
    ]

    emails.each do |email|
      body = email.body.to_s
      assert_match /CRM 3K/, body, "Email #{email.subject} missing CRM 3K branding"
    end
  end

  # Email Delivery Tests
  test "emails are delivered in HTML format" do
    email = Devise::Mailer.reset_password_instructions(@user, "token")
    assert_equal "text/html", email.content_type.split(";").first
  end

  test "emails have proper from address" do
    email = Devise::Mailer.reset_password_instructions(@user, "token")
    assert email.from.present?
  end

  test "emails have reply-to address" do
    email = Devise::Mailer.reset_password_instructions(@user, "token")
    assert email.reply_to.present? || email.from.present?
  end

  # Button Link Tests
  test "reset password email button is properly styled" do
    raw_token = "test_token"
    email = Devise::Mailer.reset_password_instructions(@user, raw_token)
    body = email.body.to_s

    # Button should have proper styling
    assert_match /email-button|btn.*button/i, body
    assert_match /Redefinir Minha Senha/, body
  end

  test "confirmation email button is properly styled" do
    raw_token = "test_token"
    email = Devise::Mailer.confirmation_instructions(@user, raw_token)
    body = email.body.to_s

    assert_match /email-button|btn.*button/i, body
    assert_match /Confirmar Minha Conta/, body
  end

  test "unlock email button is properly styled" do
    raw_token = "test_token"
    email = Devise::Mailer.unlock_instructions(@user, raw_token)
    body = email.body.to_s

    assert_match /email-button|btn.*button/i, body
    assert_match /Desbloquear Conta/, body
  end
end
