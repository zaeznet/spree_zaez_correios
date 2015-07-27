require 'spec_helper'

module Spree
  module Stock
    describe Estimator do
      let!(:shipping_method) { create(:shipping_method) }
      let(:package) { build(:stock_package, contents: inventory_units.map { |i| ContentItem.new(inventory_unit) }) }
      let(:order) { build(:order_with_line_items) }
      let(:inventory_units) { order.inventory_units }

      subject { Estimator.new(order) }

      context '#shipping rates' do
        before(:each) do
          shipping_method.zones.first.members.create(:zoneable => order.ship_address.country)
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :available?).and_return(true)
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :compute).and_return({cost: 4.00, delivery_time: 1})
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :preferences).and_return({:currency => currency})
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :marked_for_destruction?)

          allow(package).to receive_messages(:shipping_methods => [shipping_method])
        end

        let(:currency) { 'USD' }

        it 'should save the delivery time on shipping rate' do
          shipping_rates = subject.shipping_rates(package)
          expect(shipping_rates.first.delivery_time).to eq 1
        end
      end
    end
  end
end