shared_examples_for 'correios calculator' do

  before { @calculator = subject.class.new }

  context 'compute_package' do

    # @param url [String]
    #
    # @return [price Float, delivery_time Integer]
    #
    def get_correios_price_and_value_for(url)
      doc = Nokogiri::XML(open(url))
      price = doc.css('Valor').first.content.sub(/,(\d\d)$/, '.\1').to_f
      delivery_time = doc.css('PrazoEntrega').first.content.to_i
      return price, delivery_time
    end

    before do
      address = FactoryGirl.build(:address, zipcode: '17209420')
      variant = FactoryGirl.build(:variant, weight: 1, height: 5, width: 15, depth: 20)

      @order = FactoryGirl.build(:order_with_shipments, ship_address: address)
      line_item = FactoryGirl.build(:line_item, variant: variant, price: 100, order: @order)
      @order.line_items << line_item

      # stock location
      @stock_location = FactoryGirl.build(:stock_location, zipcode: '08465312')

      # shipment
      @shipment = FactoryGirl.build(:shipment, order: @order, stock_location: @stock_location)
      @shipment.inventory_units << FactoryGirl.build(:inventory_unit, variant: variant, order: @order, line_item: line_item, shipment: @shipment)

      # package
      @package = @shipment.to_package
      @package.add @shipment.inventory_units.first

      # default query
      @default_query = {
          nCdEmpresa: nil,
          sDsSenha: nil,
          sCepOrigem: '08465312',
          sCepDestino: '17209420',
          nVlPeso: 1,
          nCdFormato: 1,
          nVlComprimento: 20,
          nVlAltura: 5,
          nVlLargura: 15,
          sCdMaoPropria: 'n',
          nVlValorDeclarado: 0,
          sCdAvisoRecebimento: 'n',
          nCdServico: @calculator.shipping_code,
          nVlDiametro: 0,
          StrRetorno: 'xml'
      }
    end

    it 'should calculate shipping cost and delivery time' do
      price, delivery_time = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?#{@default_query.to_query}")

      expect(@calculator.compute_package(@package)[:cost]).to eq(price)
      expect(@calculator.delivery_time).to eq(delivery_time)
    end

    it 'should possible add days to delivery time' do
      price, delivery_time = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?#{@default_query.to_query}")

      @calculator.preferred_additional_days = 3

      @calculator.compute_package(@package)
      expect(@calculator.delivery_time).to eq(delivery_time + 3)
    end

    it 'should possible add some value to price' do
      price, delivery_time = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?#{@default_query.to_query}")

      @calculator.preferred_additional_value = 10.0

      expect(@calculator.compute_package(@package)[:cost]).to eq(price + 10.0)
    end

    it 'should change price according to declared value' do
      query = @default_query.merge({nVlValorDeclarado: '100,00'})
      price, delivery_time = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?#{query.to_query}")

      @calculator.preferred_declared_value = true
      expect(@calculator.compute_package(@package)[:cost]).to eq(price)
    end

    it 'should change price according to in hands' do
      query = @default_query.merge({sCdMaoPropria: 's'})
      price, delivery_time = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?#{query.to_query}")

      @calculator.preferred_receive_in_hands = true
      expect(@calculator.compute_package(@package)[:cost]).to eq(price)
    end

    it 'should change price according to receipt notification' do
      query = @default_query.merge({sCdAvisoRecebimento: 's'})
      price, delivery_time = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?#{query.to_query}")

      @calculator.preferred_receipt_notification = true
      expect(@calculator.compute_package(@package)[:cost]).to eq(price)
    end
  end
end