require 'simplecov'
require 'minitest/autorun'

require 'tilia/xml'

# Extend the assertions
require 'minitest/assertions'
module Minitest
  module Assertions
    def assert_xml_equal(expected, actual, message = nil)
      assert(
        Hash.from_xml(actual) == Hash.from_xml(expected),
        message || ">>> expected:\n#{expected}\n<<<\n>>> got:\n#{actual}\n<<<"
      )
    end

    def assert_instance_equal(expected, actual, message = nil)
      assert(
        compare_instances(expected, actual),
        message || ">>> expected:\n#{expected.inspect}\n<<<\n>>> got:\n#{actual.inspect}\n<<<"
      )
    end

    def assert_has_key(key, hash, message = nil)
      assert(
        hash.key?(key),
        message || "expected #{hash.inspect} to have key #{key.inspect}"
      )
    end

    def assert_v_object_equals(expected, actual, message = nil)
      get_obj = lambda do |input|
        input = input.read if input.respond_to?(:read)

        input = Tilia::VObject::Reader.read(input) if input.is_a?(String)

        unless input.is_a?(Tilia::VObject::Component)
          fail ArgumentError, 'Input must be a string, stream or VObject component'
        end

        input.delete('PRODID')
        if input.is_a?(Tilia::VObject::Component::VCalendar) && input['CALSCALE'].to_s == 'GREGORIAN'
          input.delete('CALSCALE')
        end
        input
      end

      assert_equal(
        get_obj.call(expected).serialize,
        get_obj.call(actual).serialize,
        message
      )
    end

    private

    def compare_instances(a, b)
      return true if b.__id__ == a.__id__

      # check class
      return false unless a.class == b.class

      # Instance variables should be the same
      return false unless a.instance_variables.sort == b.instance_variables.sort

      # compare all instance variables
      a.instance_variables.each do |var|
        if a.instance_variable_get(var) == a
          # Referencing self
          return false unless b.instance_variable_get(var) == b
        else
          unless a.instance_variable_get(var) == b.instance_variable_get(var) ||
              compare_instances(a.instance_variable_get(var), b.instance_variable_get(var))
            return false
          end
        end
      end
      true
    end
  end
end
