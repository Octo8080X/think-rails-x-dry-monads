class OrderHistory < ApplicationRecord
  belongs_to :product
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :ordered_at, presence: true
  
  scope :recent, -> { order(ordered_at: :desc) }
end
