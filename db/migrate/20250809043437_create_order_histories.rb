class CreateOrderHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :order_histories do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.datetime :ordered_at

      t.timestamps
    end
  end
end
