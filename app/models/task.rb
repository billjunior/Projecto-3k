class Task < ApplicationRecord
  acts_as_tenant :tenant
  belongs_to :assigned_to_user, class_name: 'User', foreign_key: 'assigned_to_user_id', optional: true
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id', optional: true
  belongs_to :related, polymorphic: true, optional: true
  
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: %w[pendente concluida cancelada] }
  
  scope :pending, -> { where(status: 'pendente') }
  scope :completed, -> { where(status: 'concluida') }
  scope :overdue, -> { where('due_date < ? AND status = ?', Date.today, 'pendente') }
end
