class CreateStores < ActiveRecord::Migration[5.1]
  def change
    create_table :stores do |t|
      t.string :name
      t.integer :region_code
      t.float :lat
      t.float :lng
      t.integer :weekday_voucher
      t.integer :weekend_voucher
      t.string :desc
      t.string :store_img
      t.string :store_url
      t.string :menu

      t.timestamps
    end
  end
end
