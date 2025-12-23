# frozen_string_literal: true

class MissingItemPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    user.super_admin? || user.admin? || user.cyber_tech?
  end

  def show?
    user.super_admin? || user.admin? || user.cyber_tech?
  end

  def create?
    user.super_admin? || user.admin? || user.cyber_tech?
  end

  def update?
    user.super_admin? || user.admin? || user.cyber_tech?
  end

  def destroy?
    user.super_admin?
  end

  def mark_as_ordered?
    update?
  end

  def mark_as_resolved?
    update?
  end
end
