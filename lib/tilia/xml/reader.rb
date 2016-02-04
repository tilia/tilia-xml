require 'libxml'
require 'stringio'
LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER)

module Tilia
  module Xml
    # The Reader class expands upon PHP's built-in XMLReader.
    #
    # The intended usage, is to assign certain XML elements to PHP classes. These
    # need to be registered using the element_map public property.
    #
    # After this is done, a single call to parse() will parse the entire document,
    # and delegate sub-sections of the document to element classes.
    class Reader
      include Tilia::Xml::ContextStackTrait

      # Returns the current nodename in clark-notation.
      #
      # For example: "{http://www.w3.org/2005/Atom}feed".
      # Or if no namespace is defined: "{}feed".
      #
      # This method returns null if we're not currently on an element.
      #
      # @return [String, nil]
      def clark
        return nil unless local_name

        "{#{namespace_uri}}#{local_name}"
      end

      # Reads the entire document.
      #
      # This function returns an array with the following three elements:
      #    * name - The root element name.
      #    * value - The value for the root element.
      #    * attributes - An array of attributes.
      #
      # This function will also disable the standard libxml error handler (which
      # usually just results in PHP errors), and throw exceptions instead.
      #
      # @return [Hash]
      def parse
        begin
          nil while node_type != ::LibXML::XML::Reader::TYPE_ELEMENT && read # noop

          result = parse_current_element
        rescue ::LibXML::XML::Error => e
          raise Tilia::Xml::LibXmlException, e.to_s
        end

        result
      end

      # parse_get_elements parses everything in the current sub-tree,
      # and returns a an array of elements.
      #
      # Each element has a 'name', 'value' and 'attributes' key.
      #
      # If the the element didn't contain sub-elements, an empty array is always
      # returned. If there was any text inside the element, it will be
      # discarded.
      #
      # If the element_map argument is specified, the existing element_map will
      # be overridden while parsing the tree, and restored after this process.
      #
      # @param [Hash] element_map
      # @return [Array]
      def parse_get_elements(element_map = nil)
        result = parse_inner_tree(element_map)

        return [] unless result.is_a?(Array)
        result
      end

      # Parses all elements below the current element.
      #
      # This method will return a string if this was a text-node, or an array if
      # there were sub-elements.
      #
      # If there's both text and sub-elements, the text will be discarded.
      #
      # If the element_map argument is specified, the existing element_map will
      # be overridden while parsing the tree, and restored after this process.
      #
      # @param [Hash] element_map
      # @return [Array, String]
      def parse_inner_tree(element_map = nil)
        text = nil
        elements = []

        if node_type == ::LibXML::XML::Reader::TYPE_ELEMENT && empty_element?
          # Easy!
          self.next
          return nil
        end

        unless element_map.nil?
          push_context
          @element_map = element_map
        end

        return false unless read

        loop do
          # RUBY: Skip is_valid block

          case node_type
          when ::LibXML::XML::Reader::TYPE_ELEMENT
            elements << parse_current_element
          when ::LibXML::XML::Reader::TYPE_TEXT,
              ::LibXML::XML::Reader::TYPE_CDATA
            text ||= ''
            text += value
            read
          when ::LibXML::XML::Reader::TYPE_END_ELEMENT
            # Ensuring we are moving the cursor after the end element.
            read
            break
          when ::LibXML::XML::Reader::TYPE_NONE
            raise Tilia::Xml::ParseException, 'We hit the end of the document prematurely. This likely means that some parser "eats" too many elements. Do not attempt to continue parsing.'
          else
            # Advance to the next element
            read
          end
        end

        pop_context unless element_map.nil?

        elements.any? ? elements : text
      end

      # Reads all text below the current element, and returns this as a string.
      #
      # @return [String]
      def read_text
        result = ''
        previous_depth = depth

        while read && depth != previous_depth
          result += value if [
            ::LibXML::XML::Reader::TYPE_TEXT,
            ::LibXML::XML::Reader::TYPE_CDATA,
            ::LibXML::XML::Reader::TYPE_WHITESPACE
          ].include? node_type
        end

        result
      end

      # Parses the current XML element.
      #
      # This method returns arn array with 3 properties:
      #   * name - A clark-notation XML element name.
      #   * value - The parsed value.
      #   * attributes - A key-value list of attributes.
      #
      # @return [Hash]
      def parse_current_element
        name = clark

        attributes = {}

        attributes = parse_attributes if has_attributes?

        value = deserializer_for_element_name(name).call(self)

        {
          'name'       => name,
          'value'      => value,
          'attributes' => attributes
        }
      end

      # Grabs all the attributes from the current element, and returns them as a
      # key-value array.
      #
      # If the attributes are part of the same namespace, they will simply be
      # short keys. If they are defined on a different namespace, the attribute
      # name will be retured in clark-notation.
      #
      # @return [Hash]
      def parse_attributes
        attributes = {}

        while move_to_next_attribute != 0
          if namespace_uri
            # Ignoring 'xmlns', it doesn't make any sense.
            next if namespace_uri == 'http://www.w3.org/2000/xmlns/'

            name = clark
            attributes[name] = value
          else
            attributes[local_name] = value
          end
        end

        move_to_element

        attributes
      end

      # Fakes PHP method xml
      #
      # Creates a new XML::Reader instance
      #
      # @return [XML::Reader]
      def xml(input)
        raise 'XML document already loaded' if @reader

        if input.is_a?(String)
          @reader = ::LibXML::XML::Reader.string(input)
        elsif input.is_a?(File)
          @reader = ::LibXML::XML::Reader.file(input)
        elsif input.is_a?(StringIO)
          @reader = ::LibXML::XML::Reader.io(input)
        else
          raise 'Unable to load XML document'
        end
      end

      # Returns the function that should be used to parse the element identified
      # by it's clark-notation name.
      #
      # @param [String] name
      # @return [#call]
      def deserializer_for_element_name(name)
        return Element::Base.method(:xml_deserialize) unless @element_map.key?(name)

        deserializer = @element_map[name]
        return deserializer if deserializer.respond_to?(:call)

        return deserializer.method(:xml_deserialize) if deserializer.include?(XmlDeserializable)

        raise "Could not use this type as a deserializer: #{deserializer.inspect} for element: #{name}"
      end

      # Delegates missing methods to XML::Reader instance
      #
      # @return [void]
      def method_missing(name, *args)
        @reader.send(name, *args)
      end
    end
  end
end
