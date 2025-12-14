# frozen_string_literal: true

module AuthorizationHelper
  # Check if user can view a resource
  def can_view?(resource)
    return false unless current_user

    policy = policy_for(resource)
    policy.show?
  rescue Pundit::NotDefinedError
    false
  end

  # Check if user can edit/update a resource
  def can_edit?(resource)
    return false unless current_user

    policy = policy_for(resource)
    policy.update?
  rescue Pundit::NotDefinedError
    false
  end

  # Check if user can delete/destroy a resource
  def can_delete?(resource)
    return false unless current_user

    policy = policy_for(resource)
    policy.destroy?
  rescue Pundit::NotDefinedError
    false
  end

  # Check if user can create a resource of this type
  def can_create?(resource_class)
    return false unless current_user

    policy = Pundit.policy!(current_user, resource_class)
    policy.create?
  rescue Pundit::NotDefinedError
    false
  end

  # Check if user can manage (admin access) a resource
  def can_manage?(resource)
    return false unless current_user

    policy = policy_for(resource)
    policy.respond_to?(:manage?) ? policy.manage? : false
  rescue Pundit::NotDefinedError
    false
  end

  # Check if current user can access CRM
  def can_access_crm?
    current_user&.can_access_crm?
  end

  # Check if current user can access Cyber Cafe
  def can_access_cyber?
    current_user&.can_access_cyber?
  end

  # Check if current user is admin
  def admin?
    current_user&.admin? || current_user&.super_admin?
  end

  # Check if current user is super admin
  def super_admin?
    current_user&.super_admin?
  end

  # Check if current user is financial director
  def financial_director?
    current_user&.financial_director?
  end

  # Show action link if authorized
  def authorized_link_to(name, path, resource, action, options = {})
    policy = policy_for(resource)

    case action
    when :show
      return unless policy.show?
    when :edit, :update
      return unless policy.update?
    when :destroy
      return unless policy.destroy?
    end

    link_to name, path, options
  rescue Pundit::NotDefinedError
    nil
  end

  private

  def policy_for(resource)
    if resource.is_a?(Class)
      Pundit.policy!(current_user, resource)
    else
      Pundit.policy!(current_user, resource)
    end
  end
end
