Spree::Calculator::Shipping::FlatPercentItemTotal.class_eval do

  def compute_package(package)
    response = compute_from_price(total(package.contents))
    {cost: response, delivery_time: nil}
  end
end