class ProductRepository < BaseRepository
  def create(attributes)
    product = Product.new(attributes)
    if product.save
      Success(product)
    else
      Failure(product.errors)
    end
  end

  def update(id, attributes)
    product = Product.find(id)
    if product.update(attributes)
      Success(product)
    else
      Failure(product.errors)
    end
  end

  def update_stock(id, new_stock)
    product = Product.find(id)
    if product.update(stock: new_stock)
      Success(product)
    else
      Failure(product.errors)
    end
  rescue ActiveRecord::RecordNotFound
    Failure("Product not found with id: #{id}")
  end

  def find_by_id(id)
    product = Product.find(id)
    Success(product)
  rescue ActiveRecord::RecordNotFound
    Failure("Product not found with id: #{id}")
  end
end
