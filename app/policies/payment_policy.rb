# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    # Everyone except cyber_tech can view payments
    !user.cyber_tech?
  end

  def show?
    !user.cyber_tech?
  end

  def create?
    # Commercial, admin, super_admin, financial_director can create payments
    user.super_admin? || user.admin? || user.commercial?
  end

  def update?
    # Only admin, super_admin, financial_director can update payments
    user.super_admin? || user.admin? || user.financial_director?
  end

  def destroy?
    # Only super_admin can delete payments (audit purposes)
    user.super_admin?
  end

  def manage?
    user.super_admin? || user.admin?
  end
end
