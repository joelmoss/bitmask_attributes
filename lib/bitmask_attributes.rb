require 'bitmask_attributes/definition'
require 'bitmask_attributes/value_proxy'

module BitmaskAttributes
  extend ActiveSupport::Concern

  module ClassMethods
    def bitmask(attribute, options={}, &extension)
      unless options[:as] && options[:as].kind_of?(Array)
        raise ArgumentError, "Must provide an Array :as option"
      end
      bitmask_definitions[attribute] = Definition.new(attribute, options[:as].to_a,options[:null].nil? || options[:null],options[:zero_value],&extension)
      bitmask_definitions[attribute].install_on(self)
    end
    
    def bitmask_definitions
      @bitmask_definitions ||= {}
    end
    
    def bitmasks
      @bitmasks ||= {}
    end
  end  
end

ActiveRecord::Base.send :include, BitmaskAttributes