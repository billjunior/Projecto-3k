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
    # Only super_admin can update daily revenues (audit purposes)
    user.super_admin?
  end

  def destroy?
    # Only super_admin can delete daily revenues (audit purposes)
    user.super_admin?
  end

  def manage?
    user.super_admin?
  end
end
