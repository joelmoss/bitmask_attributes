module BitmaskAttributes
  class ValueProxy < Array
      
    def initialize(record, attribute, &extension)
      @record = record
      @attribute = attribute
      find_mapping
      instance_eval(&extension) if extension
      super(extract_values)
    end
    
    # =========================
    # = OVERRIDE TO SERIALIZE =
    # =========================
    
    alias_method :orig_replace, :replace
    %w(push << delete replace reject! select!).each do |override|
      class_eval(<<-EOEVAL)
        def #{override}(*args)
          (super).tap do
            updated!
          end
        end
      EOEVAL
    end
    
    def to_i
      inject(0) { |memo, value| memo | @mapping[value] }
    end
  
    private
    
      def validate!
        each do |value|
          if @mapping.key? value
            true
          else
            raise ArgumentError, "Unsupported value for `#{@attribute}': #{value.inspect}"
          end
        end
      end
    
      def symbolize!
        orig_replace(map(&:to_sym))
      end

      def updated!
        validate!
        symbolize!
        uniq!
        serialize!
      end
    
      def serialize!
        @record.send(:write_attribute, @attribute, to_i)
      end
  
      def extract_values
        stored = [@record.send(:read_attribute, @attribute) || 0, 0].max
        @mapping.inject([]) do |values, (value, bitmask)|
          values.tap do
            values << value.to_sym if (stored & bitmask > 0)
          end
        end        
      end
    
      def find_mapping
        unless (@mapping = @record.class.bitmasks[@attribute])
          raise ArgumentError, "Could not find mapping for bitmask attribute :#{@attribute}"
        end
      end
      
  end
end
