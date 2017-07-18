class CreateVouchers < ActiveRecord::Migration[5.1]
  def change
    create_table :vouchers do |t|
      t.references :user, foreign_key: true
      t.references :drink, foreign_key: true
      t.boolean :is_used, default: false
      t.integer :rating

      t.timestamps
    end
  end
end
