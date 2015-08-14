module Spree
  class Calculator::Shipping::CorreiosBaseCalculator < Spree::ShippingCalculator
    preference :token,    :string
    preference :password, :string
    preference :additional_days,  :integer, default: 0
    preference :additional_value, :integer, default: 0
    preference :declared_value,       :boolean, default: false
    preference :receipt_notification, :boolean, default: false
    preference :receive_in_hands,     :boolean, default: false

    # Tamanhos maximos que um pacote pode ter para ser enviado pelos correios
    # Soma maxima das dimensoes (compr. + alt. + larg.)
    #
    # documentacao em: http://www.correios.com.br/para-voce/precisa-de-ajuda/limites-de-dimensoes-e-de-peso
    #
    MAX_WIDTH = 105
    MAX_DEPTH = 105
    MAX_HEIGHT = 105
    MAX_DIMENSIONS = 200

    attr_reader :delivery_time

    # Calculates the shipping cost
    #
    # Algorithm inspired in Opencart extension created by Thalles Cardoso <thallescard@gmail.com>
    #
    # @param package [Spree::Package]
    #
    # @return [Hash]
    #
    def compute_package package
      return if package.nil?
      @order = package.order

      @stock_location = package.stock_location

      pkg = Correios::Frete::Pacote.new
      pkg_dimensions = {width: 0, height: 0, depth: 0, weight: 0}
      packages = [pkg]

      package.contents.each do |item|
        return {} unless valid_dimensions?(item.variant)

        new_width = item.variant.width + pkg_dimensions[:width]
        new_height = item.variant.height + pkg_dimensions[:height]
        new_depth = item.variant.depth + pkg_dimensions[:depth]
        new_weight = item.variant.weight + pkg_dimensions[:weight]

        if (new_width <= MAX_WIDTH and verify_max_dimensions(pkg_dimensions, item.variant, :width)) and (new_weight <= max_weight)
          pkg_dimensions[:weight] += item.variant.weight

          pkg_dimensions[:width] += item.variant.width
          pkg_dimensions[:height] = pkg_dimensions[:height] >= item.variant.height ? pkg_dimensions[:height] : item.variant.height
          pkg_dimensions[:depth] = pkg_dimensions[:depth] >= item.variant.depth ? pkg_dimensions[:depth] : item.variant.depth
        elsif (new_height <= MAX_HEIGHT and verify_max_dimensions(pkg_dimensions, item.variant, :height)) and (new_weight <= max_weight)
          pkg_dimensions[:weight] += item.variant.weight

          pkg_dimensions[:height] += item.variant.height
          pkg_dimensions[:width] = pkg_dimensions[:width] >= item.variant.width ? pkg_dimensions[:width] : item.variant.width
          pkg_dimensions[:depth] = pkg_dimensions[:depth] >= item.variant.depth ? pkg_dimensions[:depth] : item.variant.depth
        elsif (new_depth <= MAX_DEPTH and verify_max_dimensions(pkg_dimensions, item.variant, :depth)) and (new_weight <= max_weight)
          pkg_dimensions[:weight] += item.variant.weight

          pkg_dimensions[:depth] += item.variant.depth
          pkg_dimensions[:height] = pkg_dimensions[:height] >= item.variant.height ? pkg_dimensions[:height] : item.variant.height
          pkg_dimensions[:width] = pkg_dimensions[:width] >= item.variant.width ? pkg_dimensions[:width] : item.variant.width
        else
          pkg = Correios::Frete::Pacote.new
          pkg_dimensions = {width: item.variant.width,
                            height: item.variant.height,
                            depth: item.variant.depth,
                            weight: item.variant.weight}

          packages << pkg
        end
        package_item = Correios::Frete::PacoteItem.new(peso: item.variant.weight.to_f,
                                                       comprimento: item.variant.depth.to_f,
                                                       largura: item.variant.width.to_f,
                                                       altura: item.variant.height.to_f)
        pkg.add_item(package_item)
      end

      value = 0
      delivery_time = 0

      packages.each do |pkg|
        response = calculate_shipping pkg

        if response.is_a? Hash
          value += response[:value]
          delivery_time = response[:delivery_time] if response[:delivery_time] > delivery_time
        else
          return {}
        end
      end

      @delivery_time = delivery_time + preferred_additional_days
      cost = value + preferred_additional_value
      {cost: cost, delivery_time: @delivery_time}
    rescue
      {}
    end

    # Verify if the store has contract to Correios
    #
    # @author Isabella Santos
    #
    # @return [Boolean]
    #
    def has_contract?
      preferred_token.present? && preferred_password.present?
    end

    protected

    # Verify if the produtct has valid dimensions for Correios
    #
    # @author Isabella Santos
    #
    # @param variant [Spree::Variant]
    #
    # @return [Boolean]
    #
    def valid_dimensions? variant
      dimensions = variant.width + variant.depth + variant.height
      if variant.width > MAX_WIDTH or variant.depth > MAX_DEPTH or
         variant.height > MAX_HEIGHT or dimensions > MAX_DIMENSIONS or
         variant.weight > max_weight
        return false
      end
      true
    end

    # Verify the size of the product and the available space inside the box
    #
    # @author Isabella Santos
    #
    # @param dimensions [Hash]
    #   used dimensions of the box
    # @param variant [Spree::Variant]
    #   variant of the package
    # @param position [Symbol]
    #   position of the box
    #   The options are: :width, :height or :depth
    #
    # @return [Boolean]
    #
    def verify_max_dimensions(dimensions, variant, position)
      case position
        when :width
          width = dimensions[:width] + variant.width
          height = dimensions[:height] >= variant.height ? dimensions[:height] : variant.height
          depth = dimensions[:depth] >= variant.depth ? dimensions[:depth] : variant.depth
        when :height
          height = dimensions[:height] + variant.height
          depth = dimensions[:depth] >= variant.depth ? dimensions[:depth] : variant.depth
          width = dimensions[:width] >= variant.width ? dimensions[:width] : variant.width
        when :depth
          depth = dimensions[:depth] + variant.depth
          height = dimensions[:height] >= variant.height ? dimensions[:height] : variant.height
          width = dimensions[:width] >= variant.width ? dimensions[:width] : variant.width
      end

      (width + height + depth) <= MAX_DIMENSIONS
    end

    # Request to Correios webservice
    # the cost and delivery time
    #
    # @param package [Correios::Frete::Pacote]
    #
    # @return [Hash]
    #
    def calculate_shipping(package)
      calculator = Correios::Frete::Calculador.new do |c|
        c.cep_origem        = @stock_location.zipcode
        c.cep_destino       = @order.ship_address.zipcode
        c.encomenda         = package
        c.mao_propria       = preferred_receive_in_hands
        c.aviso_recebimento = preferred_receipt_notification
        c.valor_declarado   = @order.amount.to_f  if preferred_declared_value
        c.codigo_empresa    = preferred_token     if preferred_token.present?
        c.senha             = preferred_password  if preferred_password.present?
      end

      webservice = calculator.calculate(shipping_method)
      return false if webservice.erro?

      {value: webservice.valor, delivery_time: webservice.prazo_entrega}
    end
  end
end