require "test_helper"

class EstimatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:one)
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 30.days.from_now
    )
    @user = User.create!(
      tenant: @tenant,
      name: "Test User",
      email: "testuser#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      confirmed_at: Time.now
    )

    @admin = User.create!(
      tenant: @tenant,
      name: "Admin User",
      email: "admin#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commercial,
      admin: true,
      confirmed_at: Time.now
    )

    @customer = Customer.create!(
      tenant: @tenant,
      name: "Controller Test Customer",
      customer_type: "particular",
      email: "customer#{SecureRandom.hex(4)}@example.com",
      phone: "+244 923 456 789"
    )

    @product = Product.create!(
      tenant: @tenant,
      name: "Test Product",
      base_price: 50000,
      category: "grafica",
      unit: "unidade",
      active: true
    )

    @estimate = Estimate.create!(
      tenant: @tenant,
      customer: @customer,
      estimate_number: "EST-CTRL-#{SecureRandom.hex(4)}",
      status: 'rascunho',
      total_value: 100000,
      valid_until: 30.days.from_now,
      created_by_user: @user
    )

    EstimateItem.create!(
      tenant: @tenant,
      estimate: @estimate,
      product: @product,
      quantity: 2,
      unit_price: 50000
    )

    @company_settings = CompanySetting.create!(
      tenant: @tenant,
      company_name: "Test Company",
      director_general_email: "director@test.com",
      financial_director_email: "financial@test.com"
    )

    sign_in @user
    ActsAsTenant.current_tenant = @tenant
  end

  # PDF Action Tests
  test "should generate PDF for estimate" do
    get pdf_estimate_url(@estimate)

    assert_response :success
    assert_equal 'application/pdf', response.content_type
    assert response.body.bytesize > 0
  end

  test "PDF filename includes estimate number" do
    get pdf_estimate_url(@estimate)

    assert_response :success
    assert_match /orcamento_#{@estimate.estimate_number}\.pdf/, response.headers['Content-Disposition']
  end

  test "PDF is displayed inline" do
    get pdf_estimate_url(@estimate)

    assert_response :success
    assert_match /inline/, response.headers['Content-Disposition']
  end

  test "should require authorization for PDF" do
    # Create estimate for different tenant
    other_tenant = Tenant.create!(
      name: "Other Company",
      subdomain: "other#{SecureRandom.hex(4)}",
      status: :active
    )

    other_customer = Customer.create!(
      tenant: other_tenant,
      name: "Other Customer",
      email: "other#{SecureRandom.hex(4)}@example.com"
    )

    other_estimate = Estimate.create!(
      tenant: other_tenant,
      customer: other_customer,
      estimate_number: "EST-OTHER-#{SecureRandom.hex(4)}",
      status: 'rascunho',
      total_value: 50000
    )

    # Should not be able to access other tenant's estimate
    assert_raises(ActiveRecord::RecordNotFound) do
      get pdf_estimate_url(other_estimate)
    end
  end

  # Submit for Approval Tests
  test "should submit estimate for approval" do
    post submit_for_approval_estimate_url(@estimate)

    @estimate.reload
    assert_equal 'pendente_aprovacao', @estimate.status
    assert_redirected_to @estimate
    assert_match /enviado para aprovação/, flash[:notice]
  end

  test "submit for approval sends emails to managers" do
    assert_enqueued_jobs 2, only: ActionMailer::MailDeliveryJob do
      post submit_for_approval_estimate_url(@estimate)
    end
  end

  test "cannot submit already approved estimate" do
    @estimate.update!(status: 'aprovado')

    post submit_for_approval_estimate_url(@estimate)

    assert_redirected_to @estimate
    assert_match /Não é possível/, flash[:alert]
  end

  # Approve Tests
  test "admin can approve estimate" do
    sign_in @admin
    @estimate.update!(status: 'pendente_aprovacao')

    post approve_estimate_url(@estimate)

    @estimate.reload
    assert_equal 'aprovado', @estimate.status
    assert_equal @admin.email, @estimate.approved_by
    assert_not_nil @estimate.approved_at
    assert_redirected_to @estimate
  end

  test "approve sends email to customer" do
    sign_in @admin
    @estimate.update!(status: 'pendente_aprovacao')

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      post approve_estimate_url(@estimate)
    end
  end

  test "approve does not send email if customer has no email" do
    sign_in @admin
    @estimate.customer.update!(email: nil)
    @estimate.update!(status: 'pendente_aprovacao')

    assert_no_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      post approve_estimate_url(@estimate)
    end
  end

  test "commercial user cannot approve estimate" do
    @estimate.update!(status: 'pendente_aprovacao')

    post approve_estimate_url(@estimate)

    # Should redirect with error (not authorized)
    assert_redirected_to estimates_path
    assert_match /Apenas gestores/, flash[:alert]
  end

  # Note: Financial director approval is tested through the admin user tests
  # since there's no separate "financeiro" role in the system

  test "cannot approve estimate in draft status" do
    sign_in @admin
    @estimate.update!(status: 'rascunho')

    post approve_estimate_url(@estimate)

    @estimate.reload
    assert_equal 'rascunho', @estimate.status
    assert_match /não pode ser aprovado/, flash[:alert]
  end

  # Reject Tests
  test "admin can reject estimate" do
    sign_in @admin
    @estimate.update!(status: 'pendente_aprovacao')

    post reject_estimate_url(@estimate)

    @estimate.reload
    assert_equal 'recusado', @estimate.status
    assert_redirected_to @estimate
  end

  test "commercial user cannot reject estimate" do
    @estimate.update!(status: 'pendente_aprovacao')

    post reject_estimate_url(@estimate)

    assert_redirected_to estimates_path
    assert_match /Apenas gestores/, flash[:alert]
  end

  # Authorization Tests
  test "requires login to access estimates" do
    sign_out @user

    get estimates_url
    assert_redirected_to new_user_session_url
  end

  test "user can only see own tenant estimates" do
    # Create another tenant
    other_tenant = Tenant.create!(
      name: "Another Tenant",
      subdomain: "another#{SecureRandom.hex(4)}",
      status: :active
    )

    other_customer = Customer.create!(
      tenant: other_tenant,
      name: "Other Customer",
      email: "other#{SecureRandom.hex(4)}@example.com"
    )

    other_estimate = Estimate.create!(
      tenant: other_tenant,
      customer: other_customer,
      estimate_number: "EST-#{SecureRandom.hex(4)}",
      status: 'rascunho',
      total_value: 50000
    )

    get estimates_url

    assert_response :success
    # Should not see other tenant's estimate
    assert_select "table tbody tr", count: 0 # Only our estimates (which are in different tabs)
  end

  # Integration Test: Full Approval Flow
  test "full estimate approval workflow with emails and PDF" do
    # 1. Submit for approval
    assert_enqueued_jobs 2, only: ActionMailer::MailDeliveryJob do
      post submit_for_approval_estimate_url(@estimate)
    end

    @estimate.reload
    assert_equal 'pendente_aprovacao', @estimate.status

    # 2. Admin approves
    sign_in @admin

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      post approve_estimate_url(@estimate)
    end

    @estimate.reload
    assert_equal 'aprovado', @estimate.status
    assert_not_nil @estimate.approved_at
    assert_equal @admin.email, @estimate.approved_by

    # 3. Generate PDF
    get pdf_estimate_url(@estimate)

    assert_response :success
    assert_equal 'application/pdf', response.content_type
    assert response.body.bytesize > 0
  end

  private

  def sign_in(user)
    post user_session_url, params: {
      user: {
        email: user.email,
        password: 'password123'
      }
    }
  end

  def sign_out(user)
    delete destroy_user_session_url
  end
end
