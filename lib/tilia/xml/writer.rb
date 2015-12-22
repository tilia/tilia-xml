require 'libxml'
module Tilia
  module Xml
    # The XML Writer class.
    #
    # This class works exactly as PHP's built-in XMLWriter, with a few additions.
    #
    # Namespaces can be registered beforehand, globally. When the first element is
    # written, namespaces will automatically be declared.
    #
    # The write_attribute, startElement and write_element can now take a
    # clark-notation element name (example: {http://www.w3.org/2005/Atom}link).
    #
    # If, when writing the namespace is a known one a prefix will automatically be
    # selected, otherwise a random prefix will be generated.
    #
    # Instead of standard string values, the writer can take Element classes (as
    # defined by this library) to delegate the serialization.
    #
    # The write() method can take array structures to quickly write out simple xml
    # trees.
    class Writer
      include ContextStackTrait

      protected

      # Any namespace that the writer is asked to write, will be added here.
      #
      # Any of these elements will get a new namespace definition *every single
      # time* they are used, but this array allows the writer to make sure that
      # the prefixes are consistent anyway.
      #
      # @return [Hash]
      attr_accessor :adhoc_namespaces

      # When the first element is written, this flag is set to true.
      #
      # This ensures that the namespaces in the namespaces map are only written
      # once.
      #
      # @return [Boolean]
      attr_accessor :namespaces_written

      public

      # Writes a value to the output stream.
      #
      # The following values are supported:
      #   1. Scalar values will be written as-is, as text.
      #   2. Null values will be skipped (resulting in a short xml tag).
      #   3. If a value is an instance of an Element class, writing will be
      #      delegated to the object.
      #   4. If a value is an array, two formats are supported.
      #
      #  Array format 1:
      #  [
      #    "{namespace}name1" => "..",
      #    "{namespace}name2" => "..",
      #  ]
      #
      #  One element will be created for each key in this array. The values of
      #  this array support any format this method supports (this method is
      #  called recursively).
      #
      #  Array format 2:
      #
      #  [
      #    [
      #      "name" => "{namespace}name1"
      #      "value" => "..",
      #      "attributes" => [
      #          "attr" => "attribute value",
      #      ]
      #    ],
      #    [
      #      "name" => "{namespace}name1"
      #      "value" => "..",
      #      "attributes" => [
      #          "attr" => "attribute value",
      #      ]
      #    ]
      # ]
      #
      # @param value
      # @return [void]
      def write(value)
        if value.is_a?(Numeric) || value.is_a?(String)
          write_string(value.to_s)
        elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
          write_string(value.to_s)
        elsif value.is_a? XmlSerializable
          value.xml_serialize(self)
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
              unless item.is_a?(Hash) && item.key?('name') && item.key?('value')
                fail ArgumentError, 'When passing an array to ->write with numeric indices, every item must be an array containing the "name" and "value" key'
              end

              attributes = item.key?('attributes') ? item['attributes'] : []
              name = item['name']
              item = item['value']
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

            start_element(name)
            write_attributes(attributes)
            write(item)
            end_element
          end
        else
          fail ArgumentError, "The writer cannot serialize objects of type: #{value.class}"
        end
      end

      # Starts an element.
      #
      # @param [String] name
      # @return [Boolean]
      def start_element(name)
        if name[0] == '{'
          (namespace, local_name) = Service.parse_clark_notation(name)

          if @namespace_map.key? namespace
            result = start_element_ns(@namespace_map[namespace], local_name, nil)
          else
            # An empty namespace means it's the global namespace. This is
            # allowed, but it mustn't get a prefix.
            if namespace == ''
              result = start_element(local_name)
              write_attribute('xmlns', '')
            else
              unless @adhoc_namespaces.key? namespace
                @adhoc_namespaces[namespace] = 'x' + (@adhoc_namespaces.size + 1).to_s
              end
              result = start_element_ns(@adhoc_namespaces[namespace], local_name, namespace)
            end
          end
        else
          result = @writer.start_element(name)
        end

        unless @namespaces_written
          @namespace_map.each do |ns, prefix|
            write_attribute((prefix ? 'xmlns:' + prefix : 'xmlns'), ns)
          end
          @namespaces_written = true
        end

        result
      end

      # Write a full element tag.
      #
      # This method automatically closes the element as well.
      #
      # @param [String] name
      # @param [String] content
      # @return [Boolean]
      def write_element(name, content = nil)
        start_element(name)
        write(content) unless content.nil?
        end_element
      end

      # Writes a list of attributes.
      #
      # Attributes are specified as a key->value array.
      #
      # The key is an attribute name. If the key is a 'localName', the current
      # xml namespace is assumed. If it's a 'clark notation key', this namespace
      # will be used instead.
      #
      # @param [Hash] attributes
      # @return [void]
      def write_attributes(attributes)
        attributes.each do |name, value|
          write_attribute(name, value)
        end
      end

      # Writes a new attribute.
      #
      # The name may be specified in clark-notation.
      #
      # Returns true when successful.
      #
      # @param [String] name
      # @param [String] value
      # @return [Boolean]
      def write_attribute(name, value)
        if name[0] == '{'
          (namespace, local_name) = Service.parse_clark_notation(name)
          if @namespace_map.key? namespace
            # It's an attribute with a namespace we know
            write_attribute(
              @namespace_map[namespace] + ':' + local_name,
              value
            )
          else
            # We don't know the namespace, we must add it in-line
            @adhoc_namespaces[namespace] = 'x' + (@adhoc_namespaces.size + 1).to_s unless @adhoc_namespaces.key?(namespace)

            write_attribute_ns(
              @adhoc_namespaces[namespace],
              local_name,
              namespace,
              value
            )
          end
        else
          @writer.write_attribute(name, value)
        end
      end

      # TODO: document this
      def initialize
        @adhoc_namespaces = {}
        @namespaces_written = false
        initialize_context_stack_attributes
      end

      # TODO: documentation
      def open_memory
        fail 'XML document already created' if @writer

        @writer = ::LibXML::XML::Writer.string
      end

      # TODO: documentation
      def output_memory
        @writer.result
      end

      # TODO: documentation
      def method_missing(name, *args)
        @writer.send(name, *args)
      end
    end
  end
end
