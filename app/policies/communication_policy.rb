# frozen_string_literal: true

class CommunicationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    # Cyber tech cannot access CRM communications
    !user.cyber_tech?
  end

  def show?
    !user.cyber_tech?
  end

  def create?
    # All non-cyber_tech users can create communications
    !user.cyber_tech?
  end

  def update?
    # Can update if creator or admin/super_admin
    user.super_admin? || user.admin? || record.created_by_user_id == user.id
  end

  def destroy?
    # Can delete if creator or admin/super_admin
    user.super_admin? || user.admin? || record.created_by_user_id == user.id
  end

  def mark_as_completed?
    # Same as update permissions
    update?
  end
end
