require 'bitmask_attributes/definition'
require 'bitmask_attributes/value_proxy'

module BitmaskAttributes
  extend ActiveSupport::Concern

  module ClassMethods
    def bitmask(attribute, options={}, &extension)
      unless options[:as] && options[:as].kind_of?(Array)
        raise ArgumentError, "Must provide an Array :as option"
      end

      if default = options[:default]
        after_initialize do
          send("#{attribute}=", default) unless send("#{attribute}?") || persisted?
        end
      end

      bitmask_definitions[attribute] = Definition.new(attribute,
                                                      options[:as].to_a,
                                                      options[:null].nil? || options[:null],
                                                      options[:zero_value],
                                                      &extension)

      bitmask_definitions[attribute].install_on(self)
    end

    def bitmask_definitions
      base_class_bitmask_definitions
    end

    def bitmasks
      base_class_bitmasks
    end

    protected

    def base_class_bitmask_definitions
      @bitmask_definitions ||= {}
      unless descends_from_active_record?
        @bitmask_definitions.reverse_merge! base_class.bitmask_definitions
      end
      @bitmask_definitions
    end

    def base_class_bitmasks
      @bitmasks ||= {}
      unless descends_from_active_record?
        @bitmasks.reverse_merge! base_class.bitmasks
      end
      @bitmasks
    end
  end

  def reload(*)
    super
    self.class.bitmasks.keys.each{|attribute| self.send("reload_#{attribute}")}
    self
  end
end

ActiveRecord::Base.send :include, BitmaskAttributes
