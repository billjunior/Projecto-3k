# frozen_string_literal: true

class DailyRevenuePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    user.super_admin? || user.cyber_tech?
  end

  def show?
    user.super_admin? || user.cyber_tech?
  end

  def create?
    user.super_admin? || user.cyber_tech?
  end

  def update?
    # Cyber tech can update (with audit trail)
    user.super_admin? || user.cyber_tech?
  end

  def destroy?
    # Cyber tech can delete (with audit trail)
    user.super_admin? || user.cyber_tech?
  end

  def manage?
    user.super_admin?
  end
end
