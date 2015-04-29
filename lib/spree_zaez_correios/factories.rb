FactoryGirl.define do
  factory :order_with_shipments, class: Spree::Order do
    user
    store
    ship_address
  end
end
