shared_examples_for 'correios calculator' do

  before { @calculator = subject.class.new }

  context 'compute_package' do

    # Faz a requisicao aos correios por meio da url passada com as informacoes
    #
    # @param url [String]
    #   url dos correios com as informacoes
    #
    # @return [price Float, prazo Integer]
    #
    def get_correios_price_and_value_for(url)
      doc = Nokogiri::XML(open(url))
      price = doc.css('Valor').first.content.sub(/,(\d\d)$/, '.\1').to_f
      prazo = doc.css('PrazoEntrega').first.content.to_i
      return price, prazo
    end

    before do
      address = FactoryGirl.build(:address, zipcode: '17209420')
      variant = FactoryGirl.build(:variant, weight: 1, height: 5, width: 15, depth: 20)
      @order = FactoryGirl.build(:order_with_shipments, ship_address: address)
      @order.line_items << FactoryGirl.build(:line_item, variant: variant, price: 100)
      @calculator.preferred_zipcode = '08465312'

      # stock location

    end

    it 'should calculate shipping cost and delivery time' do
      price, prazo = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=&sDsSenha=&sCepOrigem=08465312&sCepDestino=17209420&nVlPeso=1&nCdFormato=1&nVlComprimento=20&nVlAltura=5&nVlLargura=15&sCdMaoPropria=n&nVlValorDeclarado=0&sCdAvisoRecebimento=n&nCdServico=#{@calculator.shipping_code}&nVlDiametro=0&StrRetorno=xml")

      expect(@calculator.compute_package(@order)).to eq(price)
      expect(@calculator.delivery_time).to eq(prazo)
    end

    it 'should possible add days to delivery time' do
      price, prazo = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=&sDsSenha=&sCepOrigem=08465312&sCepDestino=17209420&nVlPeso=1&nCdFormato=1&nVlComprimento=20&nVlAltura=5&nVlLargura=15&sCdMaoPropria=n&nVlValorDeclarado=0&sCdAvisoRecebimento=n&nCdServico=#{@calculator.shipping_code}&nVlDiametro=0&StrRetorno=xml")

      @calculator.preferred_additional_days = 3

      @calculator.compute_package(@order)
      expect(@calculator.delivery_time).to eq(prazo + 3)
    end

    it 'should possible add some value to price' do
      price, prazo = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=&sDsSenha=&sCepOrigem=08465312&sCepDestino=17209420&nVlPeso=1&nCdFormato=1&nVlComprimento=20&nVlAltura=5&nVlLargura=15&sCdMaoPropria=n&nVlValorDeclarado=0&sCdAvisoRecebimento=n&nCdServico=#{@calculator.shipping_code}&nVlDiametro=0&StrRetorno=xml")

      @calculator.preferred_additional_value = 10.0

      @calculator.compute_package(@order)
      expect(@calculator.compute_package(@order)).to eq(price + 10.0)
    end

    it 'should change price according to declared value' do
      price, prazo = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=&sDsSenha=&sCepOrigem=08465312&sCepDestino=17209420&nVlPeso=1&nCdFormato=1&nVlComprimento=20&nVlAltura=5&nVlLargura=15&sCdMaoPropria=n&nVlValorDeclarado=100,00&sCdAvisoRecebimento=n&nCdServico=#{@calculator.shipping_code}&nVlDiametro=0&StrRetorno=xml")

      @calculator.preferred_declared_value = true
      expect(@calculator.compute_package(@order)).to eq(price)
    end

    it 'should change price according to in hands' do
      price, prazo = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=&sDsSenha=&sCepOrigem=08465312&sCepDestino=17209420&nVlPeso=1&nCdFormato=1&nVlComprimento=20&nVlAltura=5&nVlLargura=15&sCdMaoPropria=s&nVlValorDeclarado=0&sCdAvisoRecebimento=n&nCdServico=#{@calculator.shipping_code}&nVlDiametro=0&StrRetorno=xml")

      @calculator.preferred_receive_in_hands = true
      expect(@calculator.compute_package(@order)).to eq(price)
    end

    it 'should change price according to receipt notification' do
      price, prazo = get_correios_price_and_value_for("http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=&sDsSenha=&sCepOrigem=08465312&sCepDestino=17209420&nVlPeso=1&nCdFormato=1&nVlComprimento=20&nVlAltura=5&nVlLargura=15&sCdMaoPropria=n&nVlValorDeclarado=0&sCdAvisoRecebimento=s&nCdServico=#{@calculator.shipping_code}&nVlDiametro=0&StrRetorno=xml")

      @calculator.preferred_receipt_notification = true
      expect(@calculator.compute_package(@order)).to eq(price)
    end
  end
end