# this module is included in the ruby built-in Hash class in config/initializers
module Playful
  module Lang
    module Hash

      def recursive_symbolize_keys
        r = symbolize_keys
        r.each do |k, v|
          if v.is_a?(::Hash)
            r[k] = v.recursive_symbolize_keys
          end
        end
        r
      end

      def has_path?(path)
        result = false
        if path.is_a? String
          head, *tail = path.split('.')
          unless head.nil?
            head = has_key?(head) ? head : has_key?(head.to_sym) ? head.to_sym : nil
          end
          unless head.nil?
            value = fetch(head)
            result = !value.is_a?(Hash) || value.is_a?(Hash) && fetch(head).has_path?(tail.join('.'))
          end
        end
        result
      end

      def has_shape?(shape, opts = { allow_undefined_keys: false, allow_missing_keys: true, allow_nil_values: false, error_on_mismatch: false })
        existing_keys_ok = all? do |k, v|
          if !shape.has_key?(k)
            opts[:allow_missing_keys] || opts[:error_on_mismatch] && (raise "No such key #{k} and missing keys not allowed")
          elsif v.is_a?(Hash)
            shape[k].is_a?(Hash) && v.has_shape?(shape[k], opts) ||
                opts[:error_on_mismatch] && (raise "Key #{k} should be a hash but is #{v.class.to_s}")
          elsif v.is_a?(Array)
            if shape[k].is_a?(Array)
              v.all? { |i| i.is_a?(Hash) ? i.has_shape?(shape[k].first, opts) : i.is_a?(shape[k].first) } ||
                  opts[:error_on_mismatch] && (raise "Entries under key #{k} should be #{shape[k].first.inspect} but are #{v.inspect}")
            else
              opts[:error_on_mismatch] && (raise "Key #{k} is an Array but should have been #{shape[k].class.to_s}")
            end
          elsif v.nil?
            opts[:allow_nil_values] || opts[:error_on_mismatch] && (raise "Key #{k} is nil and nil values are not allowed")
          else
            v.is_a?(shape[k]) || opts[:error_on_mismatch] && (raise "Key #{k} should be #{shape[k].class.to_s} but is #{v.class.to_s}")
          end
        end

        all_keys_included = opts[:allow_undefined_keys] || (shape.keys & keys).length == keys.length

        existing_keys_ok && (all_keys_included || opts[:allow_missing_keys])
      end

      def convert_to_shape!(shape)
        convert_single_value = Proc.new do |val, type|
          if val.is_a?(String)
            if type == Integer && val =~ /^-?\d+$/
              val.to_i
            elsif type == Date
              Date.parse(val)
            elsif type == DateTime
              DateTime.parse(val)
            elsif type == Boolean
              !!val
            else
              val
            end
          else
            val
          end
        end

        each do |k, v|
          if shape.has_key?(k)
            if v.is_a?(Hash) && shape[k].is_a?(Hash)
              v.convert_to_shape!(shape[k])
            elsif v.is_a?(Array) && shape[k].is_a?(Array)
              self[k] = v.map { |val| val.is_a?(Hash) ? val.convert_to_shape!(shape[k].first) : convert_single_value.call(val, shape[k].first) }
            else
              self[k] = convert_single_value.call(v, shape[k])
            end
          end
        end

        self
      end
    end
  end
end
