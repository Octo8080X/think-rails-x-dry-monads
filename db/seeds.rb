# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# サンプル商品データを作成
products_data = [
  {
    name: "MacBook Pro",
    price: 198000,
    stock: 10,
    description: "Apple M2チップ搭載の高性能ノートパソコン。13インチRetinaディスプレイ、8GB統合メモリ、256GB SSDストレージ"
  },
  {
    name: "iPhone 15 Pro",
    price: 159800,
    stock: 25,
    description: "最新のA17 Proチップ搭載。チタニウムデザイン、ProRAWカメラ、USB-C対応"
  },
  {
    name: "AirPods Pro",
    price: 39800,
    stock: 50,
    description: "アクティブノイズキャンセリング、空間オーディオ対応の完全ワイヤレスイヤホン"
  },
  {
    name: "iPad Air",
    price: 92800,
    stock: 15,
    description: "M1チップ搭載、10.9インチLiquid Retinaディスプレイ、64GBストレージ"
  },
  {
    name: "Apple Watch Series 9",
    price: 59800,
    stock: 30,
    description: "S9チップ搭載、45mmケース、GPS + Cellularモデル、健康管理機能充実"
  }
]

products_data.each do |product_data|
  Product.find_or_create_by!(name: product_data[:name]) do |product|
    product.price = product_data[:price]
    product.stock = product_data[:stock] 
    product.description = product_data[:description]
  end
end

puts "#{Product.count} products created!"
