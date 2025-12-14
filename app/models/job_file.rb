class JobFile < ApplicationRecord
  acts_as_tenant :tenant
  belongs_to :job
  belongs_to :uploaded_by_user, class_name: 'User', foreign_key: 'uploaded_by_user_id', optional: true
  
  validates :file_path, presence: true
  validates :file_type, presence: true, inclusion: { in: %w[arte_cliente arte_final comprovativo outro] }
end
