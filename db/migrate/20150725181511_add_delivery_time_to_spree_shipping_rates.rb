class AddDeliveryTimeToSpreeShippingRates < ActiveRecord::Migration
  def change
    add_column :spree_shipping_rates, :delivery_time, :integer
  end
end
