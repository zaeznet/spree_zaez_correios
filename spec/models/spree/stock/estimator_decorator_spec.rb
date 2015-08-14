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

        it 'should not create shipping rate if cost is unknow' do
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :compute).and_return({})
          shipping_rates = subject.shipping_rates(package)
          expect(shipping_rates).to eq Array.new
        end

        it 'should save only cost if delivery time is not provided' do
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :compute).and_return(10.0)
          shipping_rate = subject.shipping_rates(package).first
          expect(shipping_rate.cost).to eq 10.0
          expect(shipping_rate.delivery_time).to be_nil
        end
      end
    end
  end
end