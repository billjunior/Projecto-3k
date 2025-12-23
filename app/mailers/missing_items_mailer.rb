class MissingItemsMailer < ApplicationMailer
  def immediate_alert(tenant, missing_item, recipient_email)
    @tenant = tenant
    @missing_item = missing_item
    @company_name = tenant.company_setting&.company_name || 'CRM 3K'

    mail(
      to: recipient_email,
      subject: "ALERTA: Item em Falta - #{@missing_item.item_name} - Urgência: #{@missing_item.urgency_text}"
    )
  end

  def weekly_summary(tenant, week_start, week_end, recipient_email)
    @tenant = tenant
    @week_start = week_start
    @week_end = week_end
    @company_name = tenant.company_setting&.company_name || 'CRM 3K'

    # Get all pending missing items
    @missing_items = MissingItem.pending.by_urgency

    # Group by urgency level
    @items_by_urgency = {
      critica: @missing_items.critica,
      alta: @missing_items.alta,
      media: @missing_items.media,
      baixa: @missing_items.baixa
    }

    # Calculate statistics
    @total_pending = @missing_items.count
    @count_critica = @items_by_urgency[:critica].count
    @count_alta = @items_by_urgency[:alta].count
    @count_media = @items_by_urgency[:media].count
    @count_baixa = @items_by_urgency[:baixa].count

    mail(
      to: recipient_email,
      subject: "Relatório Semanal de Itens em Falta - #{I18n.l(@week_start, format: :short)} a #{I18n.l(@week_end, format: :short)}"
    )
  end
end
