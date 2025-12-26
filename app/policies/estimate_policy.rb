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

  def pdf?
    show?  # Anyone who can view the estimate can see its PDF
  end

  def submit_for_approval?
    create? || update?  # Anyone who can create/update can submit
  end

  def reject?
    approve?  # Same permissions as approve
  end

  def convert_to_job?
    approve?  # Only admins can convert to job
  end

  def apply_discount?
    # Commercial, admin, super_admin can apply discounts
    user.super_admin? || user.admin? || user.commercial?
  end

  def view_pricing_analysis?
    # Directors and financial directors can view detailed pricing analysis
    user.super_admin? || user.admin? || user.role == 'financeiro'
  end

  def validate_pricing?
    # Anyone who can create/update can validate pricing
    create? || update?
  end
end
