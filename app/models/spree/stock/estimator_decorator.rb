Spree::Stock::Estimator.class_eval do

  # Override to save the delivery time
  def calculate_shipping_rates(package, ui_filter)
    shipping_methods(package, ui_filter).map do |shipping_method|
      response = shipping_method.calculator.compute(package)
      if response.is_a? Hash
        cost = response[:cost]
        delivery_time = response[:delivery_time]
      elsif %w(Float BigDecimal).include? response.class.to_s
        cost = response
        delivery_time = nil
      end

      tax_category = shipping_method.tax_category
      if tax_category
        tax_rate = tax_category.tax_rates.detect do |rate|
          # If the rate's zone matches the order's zone, a positive adjustment will be applied.
          # If the rate is from the default tax zone, then a negative adjustment will be applied.
          # See the tests in shipping_rate_spec.rb for an example of this.d
          rate.zone == order.tax_zone || rate.zone.default_tax?
        end
      end

      if cost
        rate = shipping_method.shipping_rates.new(cost: cost, delivery_time: delivery_time)
        rate.tax_rate = tax_rate if tax_rate
      end

      rate
    end.compact
  end
end