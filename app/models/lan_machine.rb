class LanMachine < ApplicationRecord
  acts_as_tenant :tenant
  # Associations
  has_many :lan_sessions, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[livre ocupado avariado reservado] }
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :available, -> { where(status: 'livre') }
  scope :occupied, -> { where(status: 'ocupado') }
  scope :active, -> { where.not(status: 'avariado') }

  def available?
    status == 'livre'
  end

  def current_session
    lan_sessions.where(status: 'aberta').last
  end
end
