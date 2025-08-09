require 'rails_helper'

RSpec.describe NewOrderService, type: :service do
  let(:product_repository) { instance_double(ProductRepository) }
  let(:order_history_repository) { instance_double(OrderHistoryRepository) }
  let(:service) { described_class.new(product_repository: product_repository, order_history_repository: order_history_repository) }

  describe '#call' do
    let(:product_id) { 1 }
    let(:quantity) { 5 }
    let(:product) { instance_double(Product, id: product_id, stock: 10) }

    context '正常なケース' do
      before do
        allow(product_repository).to receive(:find_by_id).with(product_id).and_return(Dry::Monads::Success(product))
        allow(product_repository).to receive(:update_stock).with(product_id, 5).and_return(Dry::Monads::Success(product))
        allow(order_history_repository).to receive(:create).and_return(Dry::Monads::Success(double))
      end

      it '注文が正常に処理される' do
        result = service.call(product_id: product_id, quantity: quantity)

        expect(result).to be_success
        expect(product_repository).to have_received(:find_by_id).with(product_id)
        expect(product_repository).to have_received(:update_stock).with(product_id, 5)
        expect(order_history_repository).to have_received(:create).with(
          hash_including(
            product_id: product_id,
            quantity: quantity
          )
        )
      end
    end

    context 'バリデーションエラーのケース' do
      context 'product_idが0以下の場合' do
        let(:product_id) { 0 }

        it 'バリデーションエラーを返す' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_VALIDATION_ERROR')
          expect(result.failure[:product_id]).to include('must be greater than 0')
        end
      end

      context 'quantityが0以下の場合' do
        let(:quantity) { 0 }

        it 'バリデーションエラーを返す' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_VALIDATION_ERROR')
          expect(result.failure[:quantity]).to include('must be greater than 0')
        end
      end

      context 'product_idが空の場合' do
        let(:product_id) { nil }

        it 'バリデーションエラーを返す' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_VALIDATION_ERROR')
        end
      end

      context 'quantityが空の場合' do
        let(:quantity) { nil }

        it 'バリデーションエラーを返す' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_VALIDATION_ERROR')
        end
      end
    end

    context 'ビジネスロジックエラーのケース' do
      context '商品が見つからない場合' do
        before do
          allow(product_repository).to receive(:find_by_id).with(product_id).and_return(Dry::Monads::Failure('Not found'))
        end

        it 'transaction_failedエラーを返す（do記法により自動的に処理中断）' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_TRANSACTION_FAILED')
          expect(result.failure[:product_id]).to eq(product_id)
          expect(result.failure[:quantity]).to eq(quantity)
        end
      end

      context '在庫が不足している場合' do
        let(:product) { instance_double(Product, id: product_id, stock: 3) }

        before do
          allow(product_repository).to receive(:find_by_id).with(product_id).and_return(Dry::Monads::Success(product))
        end

        it 'insufficient_stockエラーを返す' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_INSUFFICIENT_STOCK')
          expect(result.failure[:current_stock]).to eq(3)
          expect(result.failure[:requested_quantity]).to eq(quantity)
        end
      end

      context '在庫アップデートが失敗した場合' do
        before do
          allow(product_repository).to receive(:find_by_id).with(product_id).and_return(Dry::Monads::Success(product))
          allow(product_repository).to receive(:update_stock).with(product_id, 5).and_return(Dry::Monads::Failure('Update failed'))
        end

        it 'transaction_failedエラーを返す' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_TRANSACTION_FAILED')
          expect(result.failure[:product_id]).to eq(product_id)
          expect(result.failure[:quantity]).to eq(quantity)
        end
      end

      context '注文履歴の作成が失敗した場合' do
        before do
          allow(product_repository).to receive(:find_by_id).with(product_id).and_return(Dry::Monads::Success(product))
          allow(product_repository).to receive(:update_stock).with(product_id, 5).and_return(Dry::Monads::Success(product))
          allow(order_history_repository).to receive(:create).and_return(Dry::Monads::Failure('Create failed'))
        end

        it 'transaction_failedエラーを返す' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_TRANSACTION_FAILED')
          expect(result.failure[:product_id]).to eq(product_id)
          expect(result.failure[:quantity]).to eq(quantity)
        end
      end

      context 'トランザクション中に例外が発生した場合' do
        before do
          allow(product_repository).to receive(:find_by_id).with(product_id).and_return(Dry::Monads::Success(product))
          allow(product_repository).to receive(:update_stock).and_raise(StandardError, 'Database error')
        end

        it 'transaction_failedエラーを返す' do
          result = service.call(product_id: product_id, quantity: quantity)

          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_TRANSACTION_FAILED')
          expect(result.failure[:product_id]).to eq(product_id)
          expect(result.failure[:quantity]).to eq(quantity)
        end
      end
    end
  end

  describe 'プライベートメソッドのテスト' do
    describe '#valid_stock_and_quantity' do
      let(:product) { instance_double(Product, stock: 10) }

      context '在庫が十分な場合' do
        it 'Successを返す' do
          result = service.send(:valid_stock_and_quantity, product, 5)
          expect(result).to be_success
        end
      end

      context '在庫が不足している場合' do
        it 'Failureを返す' do
          result = service.send(:valid_stock_and_quantity, product, 15)
          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_INSUFFICIENT_STOCK')
          expect(result.failure[:current_stock]).to eq(10)
          expect(result.failure[:requested_quantity]).to eq(15)
        end
      end
    end

    describe '#product_find_by_id' do
      let(:product_id) { 1 }

      context '商品が見つかった場合' do
        let(:product) { instance_double(Product, id: product_id) }

        before do
          allow(product_repository).to receive(:find_by_id).with(product_id).and_return(Dry::Monads::Success(product))
        end

        it '商品を返す' do
          result = service.send(:product_find_by_id, product_id)
          expect(result).to be_success
          expect(result.value!).to eq(product)
        end
      end

      context '商品が見つからなかった場合' do
        before do
          allow(product_repository).to receive(:find_by_id).with(product_id).and_return(Dry::Monads::Failure('Not found'))
        end

        it 'product_not_foundエラーを返す' do
          result = service.send(:product_find_by_id, product_id)
          expect(result).to be_failure
          expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_RUNTIME_PRODUCT_NOT_FOUND')
          expect(result.failure[:product_id]).to eq(product_id)
        end
      end
    end

    describe '#create_error' do
      it '適切なエラー構造を作成する' do
        result = service.send(:create_error, :validation_error, { test: 'data' })
        
        expect(result).to be_failure
        expect(result.failure[:code]).to eq('NEW_ORDER_SERVICE_VALIDATION_ERROR')
        expect(result.failure[:test]).to eq('data')
      end
    end
  end

  describe 'Contract バリデーション' do
    let(:contract) { described_class::Contract.new }

    describe 'product_id のバリデーション' do
      it '正の整数で成功する' do
        result = contract.call(product_id: 1, quantity: 1)
        expect(result).to be_success
      end

      it '0で失敗する' do
        result = contract.call(product_id: 0, quantity: 1)
        expect(result).to be_failure
        expect(result.errors[:product_id]).to include('must be greater than 0')
      end

      it '負の数で失敗する' do
        result = contract.call(product_id: -1, quantity: 1)
        expect(result).to be_failure
        expect(result.errors[:product_id]).to include('must be greater than 0')
      end

      it '空で失敗する' do
        result = contract.call(quantity: 1)
        expect(result).to be_failure
        expect(result.errors[:product_id]).to include('is missing')
      end
    end

    describe 'quantity のバリデーション' do
      it '正の整数で成功する' do
        result = contract.call(product_id: 1, quantity: 1)
        expect(result).to be_success
      end

      it '0で失敗する' do
        result = contract.call(product_id: 1, quantity: 0)
        expect(result).to be_failure
        expect(result.errors[:quantity]).to include('must be greater than 0')
      end

      it '負の数で失敗する' do
        result = contract.call(product_id: 1, quantity: -1)
        expect(result).to be_failure
        expect(result.errors[:quantity]).to include('must be greater than 0')
      end

      it '空で失敗する' do
        result = contract.call(product_id: 1)
        expect(result).to be_failure
        expect(result.errors[:quantity]).to include('is missing')
      end
    end
  end
end
