Spree::Calculator::Shipping::FlexiRate.class_eval do

  def compute_package(package)
    response = compute_from_quantity(package.contents.sum(&:quantity))
    {cost: response, delivery_time: nil}
  end
end