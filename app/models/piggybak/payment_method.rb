module Piggybak 
  class PaymentMethod < ActiveRecord::Base
    
    # klass_enum requires the ShippingCalculator subclasses to be loaded
    shipping_calcs_path = File.expand_path("../payment_calculator", __FILE__)
    Dir.glob(shipping_calcs_path + "**/*.rb").each do |subclass|
      ActiveSupport::Dependencies.require_or_load subclass
    end 
    
    has_many :payment_method_values, :dependent => :destroy
    alias :metadata :payment_method_values

    accepts_nested_attributes_for :payment_method_values, :allow_destroy => true

    validates_presence_of :klass
    validates_presence_of :description

    def klass_enum 
       Piggybak::PaymentCalculator.subclasses
    end

    validates_each :payment_method_values do |record, attr, value|
      if record.klass
        payment_method = record.klass.constantize
        metadata_keys = value.collect { |v| v.key }.sort
        if payment_method::KEYS.sort != metadata_keys
          record.errors.add attr, "You must define key values for #{payment_method::KEYS.join(', ')} for this payment method."
        end
      end
    end
    validates_each :active do |record, attr, value|
      if value && PaymentMethod.find_all_by_active(true).select { |p| p != record }.size > 0
        record.errors.add attr, "You may only have one active payment method."
      end
    end

    def key_values
      self.metadata.inject({}) { |h, k| h[k.key.to_sym] = k.value; h }
    end

    def admin_label
      "#{self.description}"
    end
  end
end
