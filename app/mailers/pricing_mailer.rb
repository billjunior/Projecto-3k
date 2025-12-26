class PricingMailer < ApplicationMailer
  default from: 'noreply@crm3k.ao'

  def below_margin_alert(document, warning, recipient_email)
    @document = document
    @warning = warning
    @company_setting = document.tenant.company_setting
    @document_type = document.is_a?(Estimate) ? 'Orçamento' : 'Fatura'
    @document_number = document.is_a?(Estimate) ? document.estimate_number : document.invoice_number

    # Attach PDF
    pdf_service = document.is_a?(Estimate) ? EstimatePdf.new(document) : InvoicePdf.new(document)
    pdf_content = pdf_service.generate

    attachments["#{@document_type.downcase}_#{@document_number}.pdf"] = pdf_content

    mail(
      to: recipient_email,
      subject: "⚠️ ALERTA: Preço Abaixo da Margem - #{@document_type} #{@document_number}"
    )
  end
end
