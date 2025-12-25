class SubscriptionsController < ApplicationController
  skip_before_action :check_tenant_subscription, only: [:expired, :renew_request]
  before_action :authenticate_user!

  def expired
    @tenant = ActsAsTenant.current_tenant

    unless @tenant&.expired? || @tenant&.suspended?
      redirect_to root_path, notice: 'Sua subscrição está ativa!'
    end
  end

  def renew_request
    @tenant = ActsAsTenant.current_tenant

    # Aqui você pode adicionar lógica para enviar email ao suporte
    # ou redirecionar para página de pagamento

    flash[:success] = 'Solicitação de renovação enviada! Nossa equipe entrará em contato em breve.'
    redirect_to subscription_expired_path
  end
end
