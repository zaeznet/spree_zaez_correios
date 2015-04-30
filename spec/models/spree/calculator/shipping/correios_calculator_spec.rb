require 'spec_helper'

describe Spree::Calculator::Shipping::CorreiosBaseCalculator do

  before { @calculator = Spree::Calculator::Shipping::CorreiosBaseCalculator.new }

  it 'should have preferences' do
    preferences = [:token, :password, :additional_days, :additional_value, :declared_value, :receipt_notification, :receive_in_hands]
    expect(@calculator.preferences.keys).to eq(preferences)
  end

  it 'declared value should default to false' do
    expect(@calculator.preferred_declared_value).to eq(false)
  end

  it 'receipt notification should default to false' do
    expect(@calculator.preferred_receipt_notification).to eq(false)
  end

  it 'receive in hands should default to false' do
    expect(@calculator.preferred_receive_in_hands).to eq(false)
  end

  it 'should have a contract if both token and password are given' do
    expect(@calculator).not_to have_contract
    @calculator.preferred_token = 'some token'
    @calculator.preferred_password = 'some password'
    expect(@calculator).to have_contract
  end
end