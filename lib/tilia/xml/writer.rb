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
        Serializer.standard_serializer(self, value)
      end

      # Starts an element.
      #
      # @param [String] name
      # @return [Boolean]
      def start_element(name)
        if name[0] == '{'
          (namespace, local_name) = Service.parse_clark_notation(name)

          if @namespace_map.key?(namespace)
            tmp_ns = @namespace_map[namespace]
            tmp_ns = nil if tmp_ns.blank?
            result = start_element_ns(tmp_ns, local_name, nil)
          elsif namespace.blank?
            # An empty namespace means it's the global namespace. This is
            # allowed, but it mustn't get a prefix.
            result = start_element(local_name)
            write_attribute('xmlns', '')
          else
            unless @adhoc_namespaces.key?(namespace)
              @adhoc_namespaces[namespace] = 'x' + (@adhoc_namespaces.size + 1).to_s
            end
            result = start_element_ns(@adhoc_namespaces[namespace], local_name, namespace)
          end
        else
          result = @writer.start_element(name)
        end

        unless @namespaces_written
          @namespace_map.each do |ns, prefix|
            write_attribute((prefix.present? ? 'xmlns:' + prefix : 'xmlns'), ns)
          end
          @namespaces_written = true
        end

        result
      end

      # Write a full element tag and it's contents.
      #
      # This method automatically closes the element as well.
      #
      # The element name may be specified in clark-notation.
      #
      # Examples:
      #
      #    writer.write_element('{http://www.w3.org/2005/Atom}author',null)
      #    becomes:
      #    <author xmlns="http://www.w3.org/2005" />
      #
      #    writer.write_element('{http://www.w3.org/2005/Atom}author', [
      #       '{http://www.w3.org/2005/Atom}name' => 'Evert Pot',
      #    ])
      #    becomes:
      #    <author xmlns="http://www.w3.org/2005" /><name>Evert Pot</name></author>
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
          if @namespace_map.key?(namespace)
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

      # Initializes the instance variables
      def initialize
        @adhoc_namespaces = {}
        @namespaces_written = false

        super
      end

      # Fakes the php function open_memory
      #
      # Initilizes the LibXML Writer
      #
      # @return [void]
      def open_memory
        raise 'XML document already created' if @writer

        @writer = ::LibXML::XML::Writer.string
      end

      # Fakes the php function output_memory
      #
      # @return [String]
      def output_memory
        @writer.result
      end

      # Delegates missing methods to XML::Writer instance
      def method_missing(name, *args)
        @writer.send(name, *args)
      end
    end
  end
end
