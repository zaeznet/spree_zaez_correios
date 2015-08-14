shared_examples_for 'correios calculator' do

  let(:calculator) { subject.class.new }

  context 'compute_package' do

    # Stub the request to Correios Webservice
    #
    # @param params [Hash]
    #
    def stub_correios_request(params = {})
      correios_attr = {valor: 10.0, prazo_entrega: 1}.merge!(params)
      response = Correios::Frete::Servico.new(correios_attr)
      allow_any_instance_of(Correios::Frete::Calculador).to receive(:calculate).and_return(response)
    end

    let(:address) { FactoryGirl.build(:address, zipcode: '12345678') }
    let(:variant) { FactoryGirl.build(:variant, weight: 1, height: 5, width: 15, depth: 20) }
    let(:order) { FactoryGirl.build(:order_with_shipments, ship_address: address) }
    let(:line_item) {FactoryGirl.build(:line_item, variant: variant, price: 100, order: order)  }
    let(:stock_location) { FactoryGirl.build(:stock_location, zipcode: '87654321') }
    let(:shipment) { FactoryGirl.build(:shipment, order: order, stock_location: stock_location) }
    let(:inventory_unit) { FactoryGirl.build(:inventory_unit, variant: variant, order: order, line_item: line_item, shipment: shipment) }
    let(:package) do
      order.line_items << line_item
      shipment.inventory_units << inventory_unit
      package = shipment.to_package
      package.add inventory_unit
      package
    end

    it 'should calculate shipping cost and delivery time' do
      stub_correios_request

      response = calculator.compute_package(package)
      expect(response[:cost]).to eq(10.0)
      expect(response[:delivery_time]).to eq(1)
    end

    it 'should possible add days to delivery time' do
      stub_correios_request

      calculator.preferred_additional_days = 3

      response = calculator.compute_package(package)
      expect(response[:delivery_time]).to eq(4)
    end

    it 'should possible add some value to price' do
      stub_correios_request

      calculator.preferred_additional_value = 10.0

      response = calculator.compute_package(package)
      expect(response[:cost]).to eq(20.0)
    end

    it 'should change price according to declared value' do
      stub_correios_request({valor: 15.0, valor_valor_declarado: 100.0})

      calculator.preferred_declared_value = true

      response = calculator.compute_package(package)
      expect(response[:cost]).to eq(15.0)
    end

    it 'should change price according to in hands' do
      stub_correios_request({valor: 17.0, valor_mao_propria: 4.0})

      calculator.preferred_receive_in_hands = true

      response = calculator.compute_package(package)
      expect(response[:cost]).to eq(17.0)
    end

    it 'should change price according to receipt notification' do
      stub_correios_request({valor: 21.0, valor_aviso_recebimento: 5.0})

      calculator.preferred_receipt_notification = true

      response = calculator.compute_package(package)
      expect(response[:cost]).to eq(21.0)
    end

    context 'validate dimensions' do
      it 'should split in 2 boxes' do
        variant.weight = 0.3
        variant.width = 100
        variant.height = 30
        variant.depth = 30

        package.add FactoryGirl.build(:inventory_unit, variant: variant, order: order, line_item: line_item, shipment: shipment)
        package.add FactoryGirl.build(:inventory_unit, variant: variant, order: order, line_item: line_item, shipment: shipment)

        stub_correios_request

        # Pacote tem 3 produtos com as dimensoes 100x30x30
        # resultando em duas caixas
        # Cada caixa tem o frete determinado de 10
        # entao o retorno deve ser de 20

        response = calculator.compute_package(package)
        expect(response[:cost]).to eq(20.0)
      end
    end
  end

  context 'valid_dimensions?' do
    let(:variant) { FactoryGirl.build(:variant, width: 50, height: 50, depth: 50, weight: 5) }

    it 'valid if dimensions is permitted' do
      expect(calculator.send(:valid_dimensions?, variant)).to be true
    end

    it 'invalid if weight is greather than the permitted' do
      variant.weight = calculator.max_weight + 1
      expect(calculator.send(:valid_dimensions?, variant)).to be false
    end

    it 'invalid if height is greather than 105cm' do
      variant.height = 120
      expect(calculator.send(:valid_dimensions?, variant)).to be false
    end

    it 'invalid if width is greather than 105cm' do
      variant.width = 120
      expect(calculator.send(:valid_dimensions?, variant)).to be false
    end

    it 'invalid if depth is greather than 105cm' do
      variant.depth = 120
      expect(calculator.send(:valid_dimensions?, variant)).to be false
    end

    it 'invalid if sum of dimensions is greather than 200cm' do
      variant.height = 100
      variant.width = 100
      variant.depth = 100
      expect(calculator.send(:valid_dimensions?, variant)).to be false
    end
  end
end