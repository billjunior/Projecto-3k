# frozen_string_literal: true

class LanMachinePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    # Only super_admin and cyber_tech can access Cyber Cafe
    user.super_admin? || user.cyber_tech?
  end

  def show?
    user.super_admin? || user.cyber_tech?
  end

  def create?
    user.super_admin? || user.cyber_tech?
  end

  def update?
    user.super_admin? || user.cyber_tech?
  end

  def destroy?
    user.super_admin? || user.cyber_tech?
  end

  def manage?
    user.super_admin?
  end
end
