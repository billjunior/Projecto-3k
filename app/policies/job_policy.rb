# frozen_string_literal: true

class JobPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.production?
        # Production users only see jobs assigned to them or in production
        scope.where(status: [:in_production, :ready_for_delivery])
      else
        scope.all
      end
    end
  end

  def index?
    # Everyone except cyber_tech can view jobs
    !user.cyber_tech?
  end

  def show?
    !user.cyber_tech?
  end

  def create?
    # Commercial, admin, super_admin can create jobs
    user.super_admin? || user.admin? || user.commercial?
  end

  def update?
    # Production can update job status and upload files
    # Commercial, admin, super_admin have full update access
    user.super_admin? || user.admin? || user.commercial? || user.production?
  end

  def destroy?
    user.super_admin? || user.admin?
  end

  def upload_file?
    # Production, commercial, admin, super_admin can upload files
    user.super_admin? || user.admin? || user.commercial? || user.production?
  end

  def update_status?
    # Production can update status
    user.super_admin? || user.admin? || user.commercial? || user.production?
  end

  def manage?
    user.super_admin? || user.admin?
  end
end
