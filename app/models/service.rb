class Service < ApplicationRecord
  acts_as_tenant :tenant

  # Associations
  belongs_to :tenant

  # Validations
  validates :category, presence: true
  validates :name, presence: true
  validates :active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :ordered, -> { order(:category, :name) }

  # Categories
  CATEGORIES = [
    'Impressões Rápidas e Documentos',
    'Personalização',
    'Encadernação',
    'Design Gráfico',
    'Outros'
  ].freeze

  def self.categories_list
    CATEGORIES
  end

  def self.grouped_by_category
    active.ordered.group_by(&:category)
  end
end
