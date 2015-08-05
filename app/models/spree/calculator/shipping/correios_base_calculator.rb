module Spree
  class Calculator::Shipping::CorreiosBaseCalculator < Spree::ShippingCalculator
    preference :token,    :string
    preference :password, :string
    preference :additional_days,  :integer, default: 0
    preference :additional_value, :integer, default: 0
    preference :declared_value,       :boolean, default: false
    preference :receipt_notification, :boolean, default: false
    preference :receive_in_hands,     :boolean, default: false
    
    attr_reader :delivery_time
    
    def compute_package(object)
      return if object.nil?
      order = if object.is_a?(Spree::Order) then object else object.order end

      stock_location = object.stock_location
      package = Correios::Frete::Pacote.new

      object.contents.each do |item|
        weight = item.variant.weight.to_f
        depth  = item.variant.depth.to_f
        width  = item.variant.width.to_f
        height = item.variant.height.to_f
        package_item = Correios::Frete::PacoteItem.new(peso: weight, comprimento: depth, largura: width, altura: height)
        package.add_item(package_item)
      end

      calculator = Correios::Frete::Calculador.new do |c|
        c.cep_origem        = stock_location.zipcode
        c.cep_destino       = order.ship_address.zipcode
        c.encomenda         = package
        c.mao_propria       = preferred_receive_in_hands
        c.aviso_recebimento = preferred_receipt_notification
        c.valor_declarado   = order.amount.to_f  if preferred_declared_value
        c.codigo_empresa    = preferred_token    if preferred_token.present?
        c.senha             = preferred_password if preferred_password.present?
      end

      webservice = calculator.calculate(shipping_method)
      return false if webservice.erro?

      @delivery_time = webservice.prazo_entrega + preferred_additional_days
      cost = webservice.valor + preferred_additional_value
      {cost: cost, delivery_time: @delivery_time}
    rescue
      {}
    end
    
    def has_contract?
      preferred_token.present? && preferred_password.present?
    end
  end
end