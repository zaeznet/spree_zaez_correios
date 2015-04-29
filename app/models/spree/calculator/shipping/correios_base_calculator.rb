module Spree
  class Calculator::Shipping::CorreiosBaseCalculator < Spree::ShippingCalculator
    preference :zipcode,  :string
    preference :token,    :string
    preference :password, :string
    preference :additional_days,  :integer
    preference :additional_value, :float
    preference :declared_value,       :boolean, default: false
    preference :receipt_notification, :boolean, default: false
    preference :receive_in_hands,     :boolean, default: false
    
    attr_reader :delivery_time
    
    def compute_package(object)
      return if object.nil?
      order = if object.is_a?(Spree::Order) then object else object.order end

      require 'correios-frete'

      package = Correios::Frete::Pacote.new
      order.line_items.map do |item|
        weight = item.variant.weight.to_f
        depth  = item.variant.depth.to_f
        width  = item.variant.width.to_f
        height = item.variant.height.to_f
        package_item = Correios::Frete::PacoteItem.new(peso: weight, comprimento: depth, largura: width, altura: height)
        package.add_item(package_item)
      end
      
      calculator = Correios::Frete::Calculador.new do |c|
        c.cep_origem        = preferred_zipcode
        c.cep_destino       = order.ship_address.zipcode
        c.encomenda         = package
        c.mao_propria       = preferred_receive_in_hands
        c.aviso_recebimento = preferred_receipt_notification
        c.valor_declarado   = order.amount.to_f  if preferred_declared_value
        c.codigo_empresa    = preferred_token    if preferred_token.present?
        c.senha             = preferred_password if preferred_password.present?
      end

      webservice = calculator.calculate(shipping_method)
      return 0.0 if webservice.erro?

      if preferred_additional_days.present?
        @delivery_time = webservice.prazo_entrega + preferred_additional_days
      else
        @delivery_time = webservice.prazo_entrega
      end

      if preferred_additional_value.present?
        webservice.valor + preferred_additional_value
      else
        webservice.valor
      end
    rescue
      0.0
    end
    
    def available?(order)
      true
    end
    
    def has_contract?
      preferred_token.present? && preferred_password.present?
    end
  end
end