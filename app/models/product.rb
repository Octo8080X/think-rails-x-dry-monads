class Product < ApplicationRecord
  has_many :order_histories, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 255 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :description, length: { maximum: 1000 }
end
