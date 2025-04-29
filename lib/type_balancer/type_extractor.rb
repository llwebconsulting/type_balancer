# frozen_string_literal: true

module TypeBalancer
  class TypeExtractor
    def initialize(type_field)
      @type_field = type_field
    end

    def extract_types(collection)
      collection.map { |item| get_type(item) }.uniq
    end

    def group_by_type(collection)
      collection.group_by { |item| get_type(item) }
    end

    private

    def get_type(item)
      if item.respond_to?(@type_field)
        item.send(@type_field)
      elsif item.respond_to?(:[])
        value = item[@type_field] || item[@type_field.to_s]
        raise TypeBalancer::Error, "Cannot access type field '#{@type_field}' on item #{item.inspect}" if value.nil?

        value
      else
        raise TypeBalancer::Error, "Cannot access type field '#{@type_field}' on item #{item.inspect}"
      end
    rescue NoMethodError, TypeError
      raise TypeBalancer::Error, "Cannot access type field '#{@type_field}' on item #{item.inspect}"
    end
  end
end
