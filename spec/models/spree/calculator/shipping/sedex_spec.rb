require 'spec_helper'

describe Spree::Calculator::Shipping::SEDEX do
  before do
    @sedex = Spree::Calculator::Shipping::SEDEX.new
  end

  it_behaves_like 'correios calculator'

  it 'should have a description' do
    expect(@sedex.description).to eq('SEDEX')
  end

  context 'without a token and password' do
    it 'should have a shipping method of :pac' do
      expect(@sedex.shipping_method).to eq(:sedex)
    end

    it 'should have a shipping code of 40010' do
      expect(@sedex.shipping_code).to eq(40010)
    end
  end

  context 'with a token and password' do
    before do
      @sedex.preferred_token = 'some token'
      @sedex.preferred_password = 'some password'
    end

    it 'should have a shipping method of :pac_com_contrato' do
      expect(@sedex.shipping_method).to eq(:sedex_com_contrato_1)
    end

    it 'should have a shipping code of 40096' do
      expect(@sedex.shipping_code).to eq(40096)
    end
  end
end