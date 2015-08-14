require 'spec_helper'

describe Spree::Calculator::Shipping::SEDEX10 do
  let(:sedex10) { subject.class.new }

  it_behaves_like 'correios calculator'

  it 'should have a description' do
    expect(sedex10.description).to eq('SEDEX 10')
  end

  context 'without a token and password' do
    it 'should have a shipping method of :pac' do
      expect(sedex10.shipping_method).to eq(:sedex_10)
    end

    it 'should have a shipping code of 40215' do
      expect(sedex10.shipping_code).to eq(40215)
    end
  end

end