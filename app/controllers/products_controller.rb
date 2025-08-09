class ProductsController < ApplicationController
  include Dry::Monads[:result]

  def index
    @products = result = Product.all
  end

  def show
    @product = Product.find(params[:id])
    @order_history = OrderHistory.new
  end
end
