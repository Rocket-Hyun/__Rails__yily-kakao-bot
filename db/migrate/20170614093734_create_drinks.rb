class CreateDrinks < ActiveRecord::Migration[5.1]
  def change
    create_table :drinks do |t|
      t.references :store, foreign_key: true
      t.string :name
      t.string :desc
      t.string :drink_img
      t.boolean :is_available, default: true

      t.timestamps
    end
  end
end
