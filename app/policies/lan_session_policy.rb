# frozen_string_literal: true

class LanSessionPolicy < ApplicationPolicy
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
    user.super_admin? || user.cyber_tech?
  end

  def destroy?
    user.super_admin? || user.cyber_tech?
  end

  def start_session?
    user.super_admin? || user.cyber_tech?
  end

  def end_session?
    user.super_admin? || user.cyber_tech?
  end

  def manage?
    user.super_admin?
  end
end
