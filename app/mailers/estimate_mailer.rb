class EstimateMailer < ApplicationMailer
  # Email sent when estimate is submitted for approval
  # Recipients: Company managers (director_general_email, financial_director_email)
  def estimate_for_approval(estimate, recipient_email)
    @estimate = estimate
    @customer = estimate.customer
    @company_settings = estimate.tenant.company_setting

    # Generate and attach PDF
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate
    attachments["orcamento_#{@estimate.estimate_number}.pdf"] = pdf_content

    mail(
      to: recipient_email,
      subject: "Novo Orçamento Aguardando Aprovação - #{@estimate.estimate_number}"
    )
  end

  # Email sent when estimate is approved
  # Recipients: Customer (customer.email)
  def estimate_approved(estimate)
    @estimate = estimate
    @customer = estimate.customer
    @company_settings = estimate.tenant.company_setting

    # Generate and attach PDF
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate
    attachments["orcamento_#{@estimate.estimate_number}.pdf"] = pdf_content

    mail(
      to: @customer.email,
      subject: "Orçamento Aprovado - #{@estimate.estimate_number}"
    )
  end

  # Email sent to directors when estimate is approved
  # Recipients: Directors (director_general_email, financial_director_email)
  def estimate_approved_notification(estimate, recipient_email, recipient_name)
    @estimate = estimate
    @customer = estimate.customer
    @company_settings = estimate.tenant.company_setting
    @recipient_name = recipient_name

    # Generate and attach PDF
    pdf_service = EstimatePdf.new(@estimate)
    pdf_content = pdf_service.generate
    attachments["orcamento_#{@estimate.estimate_number}.pdf"] = pdf_content

    mail(
      to: recipient_email,
      subject: "✅ Orçamento Aprovado - #{@estimate.estimate_number}"
    )
  end
end
