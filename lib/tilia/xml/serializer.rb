module Tilia
  module Xml
    # This file provides a number of 'serializer' helper functions.
    #
    # These helper functions can be used to easily xml-encode common PHP
    # data structures, or can be placed in the class_map.
    module Serializer
      # The 'enum' serializer writes simple list of elements.
      #
      # For example, calling:
      #
      # enum(writer, [
      #   "{http://sabredav.org/ns}elem1",
      #   "{http://sabredav.org/ns}elem2",
      #   "{http://sabredav.org/ns}elem3",
      #   "{http://sabredav.org/ns}elem4",
      #   "{http://sabredav.org/ns}elem5",
      # ])
      #
      # Will generate something like this (if the correct namespace is declared):
      #
      # <s:elem1 />
      # <s:elem2 />
      # <s:elem3 />
      # <s:elem4>content</s:elem4>
      # <s:elem5 attr="val" />
      #
      # @param [Writer] writer
      # @param [Array<String>] values
      # @return [void]
      def self.enum(writer, values)
        values.each do |value|
          writer.write_element(value)
        end
      end

      # The valueObject serializer turns a simple PHP object into a classname.
      #
      # Every public property will be encoded as an xml element with the same
      # name, in the XML namespace as specified.
      #
      # @param [Writer] writer
      # @param [Object] value_object
      # @param [String] namespace
      def self.value_object(writer, value_object, namespace)
        value_object.instance_variables.each do |key|
          value = value_object.instance_variable_get(key)

          # key is a symbol and starts with @
          key = key.to_s[1..-1]

          writer.write_element("{#{namespace}}#{key}", value)
        end
      end

      # This serializer helps you serialize xml structures that look like
      # this:
      #
      # <collection>
      #    <item>...</item>
      #    <item>...</item>
      #    <item>...</item>
      # </collection>
      #
      # In that previous example, this serializer just serializes the item element,
      # and this could be called like this:
      #
      # repeating_elements(writer, items, '{}item')
      #
      # @param [Writer] writer
      # @param [Array] items A list of items sabre/xml can serialize.
      # @param [String] child_element_name Element name in clark-notation
      # @return [void]
      def self.repeating_elements(writer, items, child_element_name)
        items.each do |item|
          writer.write_element(child_element_name, item)
        end
      end

      # This function is the 'default' serializer that is able to serialize most
      # things, and delegates to other serializers if needed.
      #
      # The standardSerializer supports a wide-array of values.
      #
      # value may be a string or integer, it will just write out the string as text.
      # value may be an instance of XmlSerializable or Element, in which case it
      #    calls it's xml_serialize method.
      # value may be a PHP callback/function/closure, in case we call the callback
      #    and give it the Writer as an argument.
      # value may be a an object, and if it's in the classMap we automatically call
      #    the correct serializer for it.
      # value may be null, in which case we do nothing.
      #
      # If value is an array, the array must look like this:
      #
      # [
      #    [
      #       'name' => '{namespaceUri}element-name',
      #       'value' => '...',
      #       'attributes' => [ 'attName' => 'attValue' ]
      #    ]
      #    [,
      #       'name' => '{namespaceUri}element-name2',
      #       'value' => '...',
      #    ]
      # ]
      #
      # This would result in xml like:
      #
      # <element-name xmlns="namespaceUri" attName="attValue">
      #   ...
      # </element-name>
      # <element-name2>
      #   ...
      # </element-name2>
      #
      # The value property may be any value standardSerializer supports, so you can
      # nest data-structures this way. Both value and attributes are optional.
      #
      # Alternatively, you can also specify the array using this syntax:
      #
      # [
      #    [
      #       '{namespaceUri}element-name' => '...',
      #       '{namespaceUri}element-name2' => '...',
      #    ]
      # ]
      #
      # This is excellent for simple key.value structures, and here you can also
      # specify anything for the value.
      #
      # You can even mix the two array syntaxes.
      #
      # @param [Writer] writer
      # @param value
      # @return [void]
      def self.standard_serializer(writer, value)
        if value.is_a?(Numeric) || value.is_a?(String)
          writer.write_string(value.to_s)
        elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
          writer.write_string(value.to_s)
        elsif value.is_a?(XmlSerializable)
          value.xml_serialize(writer)
        elsif writer.class_map.key?(value.class)
          # It's an object which class appears in the classmap.
          writer.class_map[value.class].call(writer, value)
        elsif value.respond_to?(:call)
          # A callback
          value.call(writer)
        elsif value.nil?
          # noop
        elsif value.is_a?(Hash) || value.is_a?(Array)
          # Code for ruby implementation
          if value.is_a?(Array)
            hash = {}
            value.each_with_index do |v, i|
              hash[i] = v
            end
            value = hash
          end

          value.each do |name, item|
            if name.is_a? Fixnum
              # This item has a numeric index. We expect to be an array with a name and a value.
              unless item.is_a?(Hash) && item.key?('name')
                fail ArgumentError, 'When passing an array to ->write with numeric indices, every item must be an array containing at least the "name" key'
              end

              attributes = item.key?('attributes') ? item['attributes'] : []
              name = item['name']
              item = item['value'] || []
            elsif item.is_a?(Hash) && item.key?('value')
              # This item has a text index. We expect to be an array with a value and optional attributes.
              attributes = item.key?('attributes') ? item['attributes'] : []
              item = item['value']
            else
              # If it's an array with text-indices, we expect every item's
              # key to be an xml element name in clark notation.
              # No attributes can be passed.
              attributes = []
            end

            writer.start_element(name)
            writer.write_attributes(attributes)
            writer.write(item)
            writer.end_element
          end
        else
          fail ArgumentError, "The writer cannot serialize objects of type: #{value.class}"
        end
      end
    end
  end
end
