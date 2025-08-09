class OrderHistoryRepository < BaseRepository
  def create(attributes)
    order_history = OrderHistory.new(attributes)
    if order_history.save
      Success(order_history)
    else
      Failure(order_history.errors)
    end
  end
end
