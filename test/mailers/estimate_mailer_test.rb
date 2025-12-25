require "test_helper"

class EstimateMailerTest < ActionMailer::TestCase
  setup do
    @tenant = tenants(:one)
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 30.days.from_now
    )
    @customer = Customer.create!(
      tenant: @tenant,
      name: "Test Customer",
      customer_type: "particular",
      email: "customer#{SecureRandom.hex(4)}@example.com",
      phone: "+244 923 456 789",
      address: "Test Address"
    )

    @estimate = Estimate.create!(
      tenant: @tenant,
      customer: @customer,
      estimate_number: "EST-#{SecureRandom.hex(4)}",
      status: 'rascunho',
      total_value: 100000,
      valid_until: 30.days.from_now,
      notes: "Test estimate"
    )

    @company_settings = CompanySetting.create!(
      tenant: @tenant,
      company_name: "Test Company",
      email: "company@test.com",
      phone: "+244 123 456 789",
      director_general_email: "director@test.com",
      financial_director_email: "financial@test.com"
    )
  end

  test "estimate_for_approval email sends to manager" do
    manager_email = "manager@example.com"
    email = EstimateMailer.estimate_for_approval(@estimate, manager_email)

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      email.deliver_now
    end

    assert_equal [manager_email], email.to
    assert_match "Novo Orçamento Aguardando Aprovação", email.subject
    assert_match @estimate.estimate_number, email.subject
  end

  test "estimate_for_approval includes estimate details" do
    manager_email = "manager@example.com"
    email = EstimateMailer.estimate_for_approval(@estimate, manager_email)

    # Should include estimate number
    assert_match @estimate.estimate_number, email.body.encoded
    # Should include customer name
    assert_match @customer.name, email.body.encoded
    # Should include total value
    assert_match /100.*000/, email.body.encoded
  end

  test "estimate_for_approval includes PDF attachment" do
    manager_email = "manager@example.com"
    email = EstimateMailer.estimate_for_approval(@estimate, manager_email)

    # Should have one attachment
    assert_equal 1, email.attachments.count

    # Attachment should be a PDF
    attachment = email.attachments.first
    assert_match /orcamento_.*\.pdf/, attachment.filename
    assert_equal 'application/pdf', attachment.content_type
    assert attachment.body.raw_source.bytesize > 0
  end

  test "estimate_approved email sends to customer" do
    email = EstimateMailer.estimate_approved(@estimate)

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      email.deliver_now
    end

    assert_equal [@customer.email], email.to
    assert_match "Orçamento Aprovado", email.subject
    assert_match @estimate.estimate_number, email.subject
  end

  test "estimate_approved includes estimate details" do
    @estimate.update!(
      status: 'aprovado',
      approved_by: 'admin@test.com',
      approved_at: Time.current
    )

    email = EstimateMailer.estimate_approved(@estimate)

    # Should include estimate number
    assert_match @estimate.estimate_number, email.body.encoded
    # Should include customer name
    assert_match @customer.name, email.body.encoded
    # Should include approved by
    assert_match @estimate.approved_by, email.body.encoded
  end

  test "estimate_approved handles missing approved_at gracefully" do
    # Estimate without approved_at should still work
    email = EstimateMailer.estimate_approved(@estimate)

    assert_nothing_raised do
      email.deliver_now
    end
  end

  test "estimate_approved handles missing approved_by gracefully" do
    @estimate.update!(approved_at: Time.current, approved_by: nil)

    email = EstimateMailer.estimate_approved(@estimate)

    assert_nothing_raised do
      email.deliver_now
    end
  end

  test "estimate_approved includes PDF attachment" do
    email = EstimateMailer.estimate_approved(@estimate)

    # Should have one attachment
    assert_equal 1, email.attachments.count

    # Attachment should be a PDF
    attachment = email.attachments.first
    assert_match /orcamento_.*\.pdf/, attachment.filename
    assert_equal 'application/pdf', attachment.content_type
    assert attachment.body.raw_source.bytesize > 0
  end

  test "estimate_for_approval includes company name when available" do
    manager_email = "manager@example.com"
    email = EstimateMailer.estimate_for_approval(@estimate, manager_email)

    assert_match @company_settings.company_name, email.body.encoded
  end

  test "estimate_approved includes company name when available" do
    email = EstimateMailer.estimate_approved(@estimate)

    assert_match @company_settings.company_name, email.body.encoded
  end

  test "estimate_for_approval works without company_settings" do
    @company_settings.destroy

    manager_email = "manager@example.com"
    email = EstimateMailer.estimate_for_approval(@estimate, manager_email)

    assert_nothing_raised do
      email.deliver_now
    end

    # Should use fallback company name
    assert_match "CRM 3K", email.body.encoded
  end

  test "estimate_approved works without company_settings" do
    @company_settings.destroy

    email = EstimateMailer.estimate_approved(@estimate)

    assert_nothing_raised do
      email.deliver_now
    end

    # Should use fallback company name
    assert_match "CRM 3K", email.body.encoded
  end

  test "estimate_for_approval includes valid_until when present" do
    manager_email = "manager@example.com"
    email = EstimateMailer.estimate_for_approval(@estimate, manager_email)

    # Should mention valid until date
    assert_match /Válido até/, email.body.encoded
  end

  test "estimate_approved handles missing valid_until gracefully" do
    @estimate.update!(valid_until: nil)

    email = EstimateMailer.estimate_approved(@estimate)

    assert_nothing_raised do
      email.deliver_now
    end
  end

  test "estimate_for_approval has both HTML and text versions" do
    manager_email = "manager@example.com"
    email = EstimateMailer.estimate_for_approval(@estimate, manager_email)

    # Should have multipart email (HTML + text)
    assert email.multipart?
    assert_equal 2, email.parts.count

    # Check parts
    html_part = email.parts.find { |p| p.content_type =~ /html/ }
    text_part = email.parts.find { |p| p.content_type =~ /plain/ }

    assert_not_nil html_part
    assert_not_nil text_part
  end

  test "estimate_approved has both HTML and text versions" do
    email = EstimateMailer.estimate_approved(@estimate)

    # Should have multipart email (HTML + text)
    assert email.multipart?
    assert_equal 2, email.parts.count

    # Check parts
    html_part = email.parts.find { |p| p.content_type =~ /html/ }
    text_part = email.parts.find { |p| p.content_type =~ /plain/ }

    assert_not_nil html_part
    assert_not_nil text_part
  end
end
