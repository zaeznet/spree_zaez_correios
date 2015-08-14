module Spree
  class Calculator::Shipping::SEDEX10 < Calculator::Shipping::CorreiosBaseCalculator
    def self.description
      'SEDEX 10'
    end
    
    def shipping_method
      :sedex_10
    end
    
    def shipping_code
      40215
    end

    def max_weight
      10
    end
  end
end
