module Spree
  class Calculator::Shipping::PAC < Calculator::Shipping::CorreiosBaseCalculator

    def self.description
      'PAC'
    end
    
    def shipping_method
      if has_contract?
        :pac_com_contrato
      else
        :pac
      end
    end
    
    def shipping_code
      if has_contract?
        41068
      else
        41106
      end
    end

    def max_weight
      30
    end
  end
end
