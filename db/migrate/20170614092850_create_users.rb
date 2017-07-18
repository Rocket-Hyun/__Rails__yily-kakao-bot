class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :user_key
      t.string :name
      t.string :number
      t.integer :sex
      t.integer :age
      t.string :state_code, default: "002000000"
      t.boolean :is_premium, default: false

      t.timestamps
    end
  end
end
