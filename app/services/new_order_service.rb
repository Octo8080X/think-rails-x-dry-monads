class NewOrderService < BaseService

  ERROR_CODES = {
    validation_error: 'NEW_ORDER_SERVICE_VALIDATION_ERROR',
    insufficient_stock: 'NEW_ORDER_SERVICE_RUNTIME_INSUFFICIENT_STOCK',
    product_not_found: 'NEW_ORDER_SERVICE_RUNTIME_PRODUCT_NOT_FOUND',
    transaction_failed: 'NEW_ORDER_SERVICE_RUNTIME_TRANSACTION_FAILED'
  }.freeze

  # バリデーションコントラクトを定義
  class Contract < Dry::Validation::Contract
    params do
      required(:product_id).filled(:integer)
      required(:quantity).filled(:integer)
    end
    
    rule(:product_id) do
      key.failure('must be greater than 0') if value <= 0
    end
    
    rule(:quantity) do
      key.failure('must be greater than 0') if value <= 0
    end
  end

  def initialize(product_repository: ProductRepository.new, order_history_repository: OrderHistoryRepository.new)
    @product_repository = product_repository
    @order_history_repository = order_history_repository
    @contract = Contract.new
  end

  def call(product_id:, quantity:)
    # バリデーション実行
    validation_result = @contract.call(product_id: product_id, quantity: quantity)
    
    return create_error(:validation_error, validation_result.errors) if validation_result.failure?
    
    # バリデーション済みの値を使用
    validated_params = validation_result.values
    
    # ビジネスロジック実行
    execute_order(validated_params)
  end

  private

  def execute_order(params)
    # 商品の在庫確認
    product = yield product_find_by_id(params[:product_id])    
    
    # 在庫チェック
    quantity_valid = valid_stock_and_quantity(product, params[:quantity])

    # 後続の処理のyieldではなく明示的にチェック
    return quantity_valid if !quantity_valid.success?

    new_stock = product.stock - params[:quantity]
      
    # 注文履歴を作成
    order_attributes = {
      product_id: params[:product_id],
      quantity: params[:quantity],
      ordered_at: Time.current
    }
    
    ActiveRecord::Base.transaction do
      yield @product_repository.update_stock(params[:product_id], new_stock)
      yield @order_history_repository.create(order_attributes)
      Success()
    end
  rescue StandardError => e
    create_error(
      :transaction_failed,
      {
        product_id: params[:product_id],
        quantity: params[:quantity]
      }
    )
  end

  # 在庫と割り当て数が適切かを返す
  def valid_stock_and_quantity(product, quantity)
    if product.stock < quantity
      create_error(
        :insufficient_stock,
        {
          current_stock: product.stock,
          requested_quantity: quantity
        }
      )
    else
      Success()
    end
  end

  def product_find_by_id(product_id)
    product_result = @product_repository.find_by_id(product_id)

    case product_result
    when Success
      product_result
    when Failure
      create_error(
        :product_not_found,
        { product_id: product_id }
      )
    end
  end

  def create_error(error_key, additional_data = {})
    Failure({
      code: ERROR_CODES[error_key],
      **additional_data
    })
  end
end
