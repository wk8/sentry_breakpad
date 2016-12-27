# Seemed somewhat silly to pull ActiveSupport as a dependency for just a couple
# of methods...

module SentryBreakpad
  class HashHelper
    class << self
      # merges hash2 into hash1, recursively
      def deep_merge!(hash1, hash2)
        hash2.each do |key, value|
          hash1[key] = if hash1.key?(key) && hash1[key].is_a?(Hash) && value.is_a?(Hash)
                         deep_merge!(hash1[key], value)
                       else
                         value
                       end
        end

        hash1
      end

      # recursively symbolizes a hash's keys
      def deep_symbolize_keys!(hash)
        hash.each_with_object({}) do |(key, value), new_hash|
          new_key = key.respond_to?(:to_sym) ? key.to_sym : key
          new_value = value.is_a?(Hash) ? deep_symbolize_keys!(value) : value
          new_hash[new_key] = new_value
        end
      end
    end
  end
end
