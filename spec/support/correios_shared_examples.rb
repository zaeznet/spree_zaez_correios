shared_examples_for 'correios calculator' do

  before { @calculator = subject.class.new }

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
    end

    it 'should calculate shipping cost and delivery time' do
      stub_correios_request

      response = @calculator.compute_package(@package)
      expect(response[:cost]).to eq(10.0)
      expect(response[:delivery_time]).to eq(1)
    end

    it 'should possible add days to delivery time' do
      stub_correios_request

      @calculator.preferred_additional_days = 3

      response = @calculator.compute_package(@package)
      expect(response[:delivery_time]).to eq(4)
    end

    it 'should possible add some value to price' do
      stub_correios_request

      @calculator.preferred_additional_value = 10.0

      response = @calculator.compute_package(@package)
      expect(response[:cost]).to eq(20.0)
    end

    it 'should change price according to declared value' do
      stub_correios_request({valor: 15.0, valor_valor_declarado: 100.0})

      @calculator.preferred_declared_value = true

      response = @calculator.compute_package(@package)
      expect(response[:cost]).to eq(15.0)
    end

    it 'should change price according to in hands' do
      stub_correios_request({valor: 17.0, valor_mao_propria: 4.0})

      @calculator.preferred_receive_in_hands = true

      response = @calculator.compute_package(@package)
      expect(response[:cost]).to eq(17.0)
    end

    it 'should change price according to receipt notification' do
      stub_correios_request({valor: 21.0, valor_aviso_recebimento: 5.0})

      @calculator.preferred_receipt_notification = true

      response = @calculator.compute_package(@package)
      expect(response[:cost]).to eq(21.0)
    end
  end
end