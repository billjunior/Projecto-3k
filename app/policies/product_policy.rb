# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
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
    # Admin, super_admin, commercial can create products
    user.super_admin? || user.admin? || user.commercial?
  end

  def update?
    user.super_admin? || user.admin? || user.commercial?
  end

  def destroy?
    user.super_admin? || user.admin?
  end

  def manage?
    user.super_admin? || user.admin?
  end
end
