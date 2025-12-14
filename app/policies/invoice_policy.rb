# frozen_string_literal: true

class InvoicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    !user.cyber_tech?
  end

  def show?
    !user.cyber_tech?
  end

  def create?
    # Commercial, admin, super_admin, financial_director can create invoices
    user.super_admin? || user.admin? || user.commercial?
  end

  def update?
    # Only admin, super_admin, financial_director can update invoices
    user.super_admin? || user.admin? || user.financial_director?
  end

  def destroy?
    # Only super_admin and financial_director can delete invoices
    user.super_admin? || user.financial_director?
  end

  def finalize?
    # Only admin and super_admin can finalize invoices
    user.super_admin? || user.admin?
  end

  def manage?
    user.super_admin? || user.admin?
  end
end
