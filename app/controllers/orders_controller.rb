class OrdersController < ApplicationController
  include Dry::Monads[:result]

  def index
    @order_histories = OrderHistory.all

  end

  def new
    @products = Product.all
    @order_history = OrderHistory.new
  end

  def create
    result = NewOrderService.new.call(product_id: order_params[:product_id], quantity: order_params[:quantity].to_i)
    
    case result
    when Success
      redirect_to orders_path
    when Failure
      flash[:alert] = format_error_message(result.failure)
      redirect_to new_order_path
    end
  end

  private

  def order_params
    params.require(:order_history).permit(:product_id, :quantity)
  end

  def format_error_message(error_data)
    return error_data.to_s unless error_data.has_key?(:code)

    t("errors.#{error_data.dig(:code)}")
  end
end
