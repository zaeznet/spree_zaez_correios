Spree::Calculator::Shipping::FlatRate.class_eval do

  def compute_package(package)
    {cost: self.preferred_amount, delivery_time: nil}
  end
end