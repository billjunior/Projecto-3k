class CreateLanMachines < ActiveRecord::Migration[7.1]
  def change
    create_table :lan_machines do |t|
      t.string :name
      t.string :status
      t.decimal :hourly_rate
      t.text :notes

      t.timestamps
    end
  end
end
