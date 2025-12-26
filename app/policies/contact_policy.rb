# frozen_string_literal: true

class ContactPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    # Cyber tech cannot access CRM contacts
    !user.cyber_tech?
  end

  def show?
    !user.cyber_tech?
  end

  def create?
    # Commercial, attendant, admin, super_admin can create contacts
    user.super_admin? || user.admin? || user.commercial? || user.attendant?
  end

  def update?
    # Commercial, attendant, admin, super_admin can update contacts
    user.super_admin? || user.admin? || user.commercial? || user.attendant?
  end

  def destroy?
    # Only admin and super_admin can delete contacts
    user.super_admin? || user.admin?
  end

  def set_primary?
    # Same as update permissions
    update?
  end
end
