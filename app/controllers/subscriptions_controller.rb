class SubscriptionsController < ApplicationController
  skip_before_action :check_subscription_status

  def expired
    # View will show expiration message
  end
end
