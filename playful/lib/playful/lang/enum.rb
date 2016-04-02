module Playful
  module Lang
    class Enum
      include Enumerable

      def self.const_missing(key)
        unless @hash.has_key?(key)
          raise ArgumentError.new "No constant with key #{key}"
        end

        @hash[key]
      end

      def self.each(&block)
        @hash.each(&block)
      end

      def self.values
        @hash.values
      end

      def self.include?(status)
        @hash.values.include?(status)
      end

      private

      def self.add_item(key,value)
        @hash ||= {}
        @hash[key]=value
      end
    end
  end
end
