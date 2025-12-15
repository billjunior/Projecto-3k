# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users see tasks assigned to them or created by them
      if user.super_admin? || user.admin?
        scope.all
      else
        scope.where(assigned_to_user_id: user.id)
             .or(scope.where(created_by_user_id: user.id))
      end
    end
  end

  def index?
    !user.cyber_tech?
  end

  def show?
    # Can see if assigned to them, created by them, or if admin
    !user.cyber_tech? && (
      user.super_admin? ||
      user.admin? ||
      record.assigned_to_user_id == user.id ||
      record.created_by_user_id == user.id
    )
  end

  def create?
    # Anyone except cyber_tech can create tasks
    !user.cyber_tech?
  end

  def update?
    # Can update if assigned to them, created by them, or if admin
    user.super_admin? ||
    user.admin? ||
    record.assigned_to_user_id == user.id ||
    record.created_by_user_id == user.id
  end

  def destroy?
    # Only creator or admin can delete
    user.super_admin? ||
    user.admin? ||
    record.created_by_user_id == user.id
  end

  def manage?
    user.super_admin? || user.admin?
  end
end
