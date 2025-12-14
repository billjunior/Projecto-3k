# frozen_string_literal: true

class CustomerPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    # Cyber tech cannot access CRM
    !user.cyber_tech?
  end

  def show?
    !user.cyber_tech?
  end

  def create?
    # Only admin, super_admin, commercial can create customers
    user.super_admin? || user.admin? || user.commercial?
  end

  def update?
    # Admin, super_admin, commercial, or creator can update
    user.super_admin? || user.admin? || user.commercial?
  end

  def destroy?
    # Only admin and super_admin can delete
    user.super_admin? || user.admin?
  end

  def manage?
    user.super_admin? || user.admin?
  end
end
