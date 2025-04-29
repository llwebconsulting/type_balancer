# frozen_string_literal: true

module TypeBalancer
  # Registry to memoize TypeExtractor per type_field in thread/request scope
  class TypeExtractorRegistry
    STORAGE_KEY = :type_balancer_extractors

    def self.get(type_field)
      cache[type_field] ||= TypeExtractor.new(type_field)
    end

    def self.clear!
      Thread.current[STORAGE_KEY] = nil
    end

    def self.cache
      Thread.current[STORAGE_KEY] ||= {}
    end
  end
end
