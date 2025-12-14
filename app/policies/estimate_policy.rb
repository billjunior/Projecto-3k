# frozen_string_literal: true

class EstimatePolicy < ApplicationPolicy
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
    # Commercial, attendant, admin, super_admin can create estimates
    user.super_admin? || user.admin? || user.commercial? || user.attendant?
  end

  def update?
    # Commercial, admin, super_admin can update estimates
    user.super_admin? || user.admin? || user.commercial?
  end

  def destroy?
    user.super_admin? || user.admin?
  end

  def approve?
    # Only admin and super_admin can approve estimates
    user.super_admin? || user.admin?
  end

  def manage?
    user.super_admin? || user.admin?
  end
end
