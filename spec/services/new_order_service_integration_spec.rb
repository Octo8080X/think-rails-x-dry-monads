require 'rails_helper'

RSpec.describe NewOrderService, type: :service do
  describe '統合テスト（実際のリポジトリを使用）' do
    let!(:product) { Product.create!(name: 'Test Product', price: 1000, stock: 10) }
    let(:service) { described_class.new }

    context '正常な注文処理' do
      it '商品の在庫が減り、注文履歴が作成される' do
        expect {
          result = service.call(product_id: product.id, quantity: 3)
          expect(result).to be_success
        }.to change { product.reload.stock }.from(10).to(7)
         .and change { OrderHistory.count }.by(1)

        order_history = OrderHistory.last
        expect(order_history.product_id).to eq(product.id)
        expect(order_history.quantity).to eq(3)
        expect(order_history.ordered_at).to be_present
      end
    end

    context '在庫不足のケース' do
      it '在庫が変更されず、注文履歴も作成されない' do
        initial_stock = product.stock
        initial_order_count = OrderHistory.count

        result = service.call(product_id: product.id, quantity: 15)
        
        expect(result).to be_failure
        expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_INSUFFICIENT_STOCK')
        expect(product.reload.stock).to eq(initial_stock)
        expect(OrderHistory.count).to eq(initial_order_count)
      end
    end

    context '存在しない商品IDのケース' do
      it 'transaction_failedエラーが返される' do
        expect {
          result = service.call(product_id: 99999, quantity: 1)
          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_TRANSACTION_FAILED')
        }.not_to change { OrderHistory.count }
      end
    end

    context 'バリデーションエラーのケース' do
      it '在庫も注文履歴も変更されない' do
        initial_stock = product.stock
        initial_order_count = OrderHistory.count

        result = service.call(product_id: -1, quantity: 1)
        
        expect(result).to be_failure
        expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_VALIDATION_ERROR')
        expect(product.reload.stock).to eq(initial_stock)
        expect(OrderHistory.count).to eq(initial_order_count)
      end
    end
  end
end
