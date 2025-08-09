class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.integer :price
      t.integer :stock
      t.text :description

      t.timestamps
    end
  end
end
