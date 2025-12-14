# frozen_string_literal: true

class LeadPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    # Commercial, admin, super_admin can access leads
    user.super_admin? || user.admin? || user.commercial?
  end

  def show?
    user.super_admin? || user.admin? || user.commercial?
  end

  def create?
    user.super_admin? || user.admin? || user.commercial?
  end

  def update?
    user.super_admin? || user.admin? || user.commercial?
  end

  def destroy?
    user.super_admin? || user.admin?
  end

  def convert_to_opportunity?
    user.super_admin? || user.admin? || user.commercial?
  end

  def manage?
    user.super_admin? || user.admin?
  end
end
