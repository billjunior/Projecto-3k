class CreateJobFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :job_files do |t|
      t.references :job, null: false, foreign_key: true
      t.string :file_path
      t.string :file_type
      t.references :uploaded_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
