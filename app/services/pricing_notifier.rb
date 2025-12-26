class PricingNotifier
  attr_reader :document, :user, :analysis

  def initialize(document, user: nil)
    @document = document
    @user = user
    @analysis = PricingAnalyzer.new(document).analyze
  end

  def notify_if_needed
    return false unless should_notify?

    warning = create_pricing_warning
    send_director_notifications(warning) if warning

    document.update_columns(
      below_margin_warned: true,
      below_margin_warned_at: Time.current
    )

    true
  end

  private

  def should_notify?
    # Notify if:
    # 1. There are pricing warnings (below margin)
    # 2. Not already warned for this document
    analysis[:has_warnings] && !document.below_margin_warned
  end

  def create_pricing_warning
    warning_type = if document.discount_applied?
                     'high_discount'
                   else
                     'below_margin'
                   end

    PricingWarning.create!(
      tenant: document.tenant,
      warnable: document,
      created_by_user: user,
      warning_type: warning_type,
      expected_margin: analysis[:expected_margin],
      actual_margin: analysis[:actual_margin_percentage],
      margin_deficit: analysis[:margin_deficit],
      profit_loss: analysis[:profit_loss],
      item_breakdown: { below_margin_items: analysis[:below_margin_items] },
      justification: document.discount_justification,
      director_notified: false
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create pricing warning: #{e.message}")
    nil
  end

  def send_director_notifications(warning)
    return unless warning

    company_setting = document.tenant.company_setting
    return unless company_setting

    recipients = [
      company_setting.director_general_email,
      company_setting.financial_director_email
    ].compact.reject(&:blank?).uniq

    return if recipients.empty?

    recipients.each do |email|
      begin
        PricingMailer.below_margin_alert(document, warning, email).deliver_later
      rescue => e
        Rails.logger.error("Failed to send pricing alert to #{email}: #{e.message}")
      end
    end

    # Mark warning as notified
    warning.update_columns(
      director_notified: true,
      director_notified_at: Time.current
    )
  end
end
