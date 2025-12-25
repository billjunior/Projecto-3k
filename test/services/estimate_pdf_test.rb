require "test_helper"
require "pdf/reader"

class EstimatePdfTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @tenant.update!(
      subscription_status: 'active',
      subscription_expires_at: 30.days.from_now
    )
    @customer = Customer.create!(
      tenant: @tenant,
      name: "PDF Test Customer",
      customer_type: "particular",
      email: "pdfcustomer#{SecureRandom.hex(4)}@example.com",
      phone: "+244 923 456 789",
      address: "123 Test Street"
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
      estimate_number: "EST-PDF-#{SecureRandom.hex(4)}",
      status: 'aprovado',
      total_value: 150000,
      valid_until: 30.days.from_now,
      notes: "This is a test estimate for PDF generation",
      approved_by: "admin@test.com",
      approved_at: Time.current
    )

    @estimate_item = EstimateItem.create!(
      tenant: @tenant,
      estimate: @estimate,
      product: @product,
      quantity: 3,
      unit_price: 50000,
      subtotal: 150000
    )

    @company_settings = CompanySetting.create!(
      tenant: @tenant,
      company_name: "PDF Test Company",
      email: "company@pdftest.com",
      phone: "+244 123 456 789",
      address: "456 Company Avenue"
    )
  end

  test "generates valid PDF" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    # Should generate PDF content
    assert_not_nil pdf_content
    assert pdf_content.bytesize > 0

    # Should be valid PDF (starts with PDF header)
    assert_match /^%PDF/, pdf_content
  end

  test "PDF contains estimate number" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    # Parse PDF to extract text
    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.map(&:text).join

    # Should contain estimate number
    assert_match @estimate.estimate_number, text
  end

  test "PDF contains customer information" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.map(&:text).join

    # Should contain customer name
    assert_match @customer.name, text
  end

  test "PDF contains product information" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.map(&:text).join

    # Should contain product name
    assert_match @product.name, text
  end

  test "PDF contains total value" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.map(&:text).join

    # Should contain total value (150.000 AOA formatted)
    assert_match /150.*000/, text
  end

  test "PDF contains company information" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.map(&:text).join

    # Should contain company name
    assert_match @company_settings.company_name, text
  end

  test "PDF generation works without company_settings" do
    @company_settings.destroy

    pdf_service = EstimatePdf.new(@estimate)

    assert_nothing_raised do
      pdf_content = pdf_service.generate
      assert_not_nil pdf_content
      assert pdf_content.bytesize > 0
    end
  end

  test "PDF contains valid_until date when present" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.map(&:text).join

    # Should mention valid until (Válido até)
    assert_match /V.?lido.*at.?/, text
  end

  test "PDF generation handles missing valid_until" do
    @estimate.update!(valid_until: nil)

    pdf_service = EstimatePdf.new(@estimate)

    assert_nothing_raised do
      pdf_content = pdf_service.generate
      assert_not_nil pdf_content
    end
  end

  test "PDF contains multiple items correctly" do
    # Add another item
    product2 = Product.create!(
      tenant: @tenant,
      name: "Second Product",
      unit_price: 75000,
      category: "product",
      active: true
    )

    EstimateItem.create!(
      estimate: @estimate,
      product: product2,
      quantity: 2,
      unit_price: 75000,
      subtotal: 150000
    )

    @estimate.update!(total_value: 300000)

    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.map(&:text).join

    # Should contain both products
    assert_match @product.name, text
    assert_match product2.name, text
  end

  test "PDF inherits from BasePdf and uses company header" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.first.text

    # Should have company header with name (from BasePdf)
    assert_match @company_settings.company_name, text
  end

  test "PDF size is reasonable" do
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    # PDF should be between 10KB and 500KB for a simple estimate
    assert pdf_content.bytesize > 10_000, "PDF is too small"
    assert pdf_content.bytesize < 500_000, "PDF is too large"
  end

  test "PDF does not display Prawn warning" do
    # Suppress warnings should be set
    assert Prawn::Fonts::AFM.instance_variable_get(:@hide_m17n_warning)
  end

  test "generates different PDFs for different estimates" do
    estimate2 = Estimate.create!(
      tenant: @tenant,
      customer: @customer,
      estimate_number: "EST-DIFF-#{SecureRandom.hex(4)}",
      status: 'rascunho',
      total_value: 200000,
      notes: "Different estimate"
    )

    pdf1 = EstimatePdf.new(@estimate).generate
    pdf2 = EstimatePdf.new(estimate2).generate

    # PDFs should be different
    assert_not_equal pdf1, pdf2
  end

  test "PDF handles notes correctly" do
    @estimate.update!(notes: "Special instructions: Handle with care")

    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate

    reader = PDF::Reader.new(StringIO.new(pdf_content))
    text = reader.pages.map(&:text).join

    # Should contain notes
    assert_match /Handle with care/, text
  end

  test "PDF handles empty notes" do
    @estimate.update!(notes: nil)

    pdf_service = EstimatePdf.new(@estimate)

    assert_nothing_raised do
      pdf_content = pdf_service.generate
      assert_not_nil pdf_content
    end
  end
end
