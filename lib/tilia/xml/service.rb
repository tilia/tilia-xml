module Tilia
  module Xml
    # XML parsing and writing service.
    #
    # You are encouraged to make a instance of this for your application and
    # potentially extend it, as a central API point for dealing with xml and
    # configuring the reader and writer.
    class Service
      # This is the element map. It contains a list of XML elements (in clark
      # notation) as keys and PHP class names as values.
      #
      # The PHP class names must implement Sabre\Xml\Element.
      #
      # Values may also be a callable. In that case the function will be called
      # directly.
      #
      # @return [Hash]
      attr_accessor :element_map

      # This is a list of namespaces that you want to give default prefixes.
      #
      # You must make sure you create this entire list before starting to write.
      # They should be registered on the root element.
      #
      # @return [Hash]
      attr_accessor :namespace_map

      # This is a list of custom serializers for specific classes.
      #
      # The writer may use this if you attempt to serialize an object with a
      # class that does not implement XmlSerializable.
      #
      # Instead it will look at this classmap to see if there is a custom
      # serializer here. This is useful if you don't want your value objects
      # to be responsible for serializing themselves.
      #
      # The keys in this classmap need to be fully qualified PHP class names,
      # the values must be callbacks. The callbacks take two arguments. The
      # writer class, and the value that must be written.
      #
      # function (Writer writer, object value)
      #
      # @return [Hash]
      attr_accessor :class_map

      # Initializes the xml service
      def initialize
        @element_map = {}
        @namespace_map = {}
        @class_map = {}
        @value_object_map = {}
      end

       # Returns a fresh XML Reader
      #
      # @return [Reader]
      def reader
        reader = Reader.new
        reader.element_map = @element_map
        reader
      end

      # Returns a fresh xml writer
      #
      # @return [Writer]
      def writer
        writer = Writer.new
        writer.namespace_map = @namespace_map
        writer.class_map = @class_map
        writer
      end

      # Parses a document in full.
      #
      # Input may be specified as a string or readable stream resource.
      # The returned value is the value of the root document.
      #
      # Specifying the context_uri allows the parser to figure out what the URI
      # of the document was. This allows relative URIs within the document to be
      # expanded easily.
      #
      # The root_element_name is specified by reference and will be populated
      # with the root element name of the document.
      #
      # @param [String, File, StringIO] input
      # @param [String, nil] context_uri
      # @param [Tilia::Box, nil] root_element_name
      # @raise [ParseException]
      # @return [Array, Object, String]
      def parse(input, context_uri = nil, root_element_name = Box.new)
        # Skip php short commings
        reader = self.reader
        reader.context_uri = context_uri
        reader.xml(input)

        result = reader.parse
        root_element_name.value = result['name']
        result['value']
      end

      # Parses a document in full, and specify what the expected root element
      # name is.
      #
      # This function works similar to parse, but the difference is that the
      # user can specify what the expected name of the root element should be,
      # in clark notation.
      #
      # This is useful in cases where you expected a specific document to be
      # passed, and reduces the amount of if statements.
      #
      # @param [String, Array<String>] root_element_name
      # @param [String, File, StringIO] input
      # @param [String, nil] context_uri
      # @return [void]
      def expect(root_element_name, input, context_uri = nil)
        root_element_name = [root_element_name] unless root_element_name.is_a?(Array)

        reader = self.reader
        reader.context_uri = context_uri
        reader.xml(input)

        result = reader.parse
        unless root_element_name.include?(result['name'])
          fail Tilia::Xml::ParseException, "Expected #{root_element_name.join(' or ')} but received #{result['name']} as the root element"
        end
        result['value']
      end

      # Generates an XML document in one go.
      #
      # The $rootElement must be specified in clark notation.
      # The value must be a string, an array or an object implementing
      # XmlSerializable. Basically, anything that's supported by the Writer
      # object.
      #
      # context_uri can be used to specify a sort of 'root' of the PHP application,
      # in case the xml document is used as a http response.
      #
      # This allows an implementor to easily create URI's relative to the root
      # of the domain.
      #
      # @param [String] root_element_name
      # @param [String, Array, XmlSerializable] value
      # @param [String, nil] context_uri
      # @return [void]
      def write(root_element_name, value, context_uri = nil)
        writer = self.writer
        writer.open_memory
        writer.context_uri = context_uri
        writer.set_indent(true)
        writer.start_document
        writer.write_element(root_element_name, value)
        writer.output_memory
      end

       # Map an xml element to a PHP class.
      #
      # Calling this function will automatically setup the Reader and Writer
      # classes to turn a specific XML element to a PHP class.
      #
      # For example, given a class such as :
      #
      # class Author {
      #   public first_name
      #   public last_name
      # }
      #
      # and an XML element such as:
      #
      # <author xmlns="http://example.org/ns">
      #   <firstName>...</firstName>
      #   <lastName>...</lastName>
      # </author>
      #
      # These can easily be mapped by calling:
      #
      # service.map_value_object('{http://example.org}author', 'Author')
      #
      # @param [String] element_name
      # @param [Class] klass
      # @return [void]
      def map_value_object(element_name, klass)
        namespace = Service.parse_clark_notation(element_name).first

        @element_map[element_name] = lambda do |reader|
          return Deserializer.value_object(reader, klass, namespace)
        end
        @class_map[klass] = lambda do |writer, value_object|
          return Serializer.value_object(writer, value_object, namespace)
        end
        @value_object_map[klass] = element_name
      end

      # Writes a value object.
      #
      # This function largely behaves similar to write, except that it's
      # intended specifically to serialize a Value Object into an XML document.
      #
      # The ValueObject must have been previously registered using
      # map_value_object.
      #
      # @param object
      # @param [String] context_uri
      # @return [void]
      def write_value_object(object, context_uri = nil)
        unless @value_object_map.key?(object.class)
          fail ArgumentError,
              "'#{object.class}' is not a registered value object class. Register your class with mapValueObject"
        end

        write(
          @value_object_map[object.class],
          object,
          context_uri
        )
      end

      # Parses a clark-notation string, and returns the namespace and element
      # name components.
      #
      # If the string was invalid, it will throw an InvalidArgumentException.
      #
      # @param [String] str
      # @raise [InvalidArgumentException]
      # @return [Array(String, String)]
      def self.parse_clark_notation(str)
        if str =~ /^{([^}]*)}(.*)/
          [Regexp.last_match[1] || '', Regexp.last_match[2]]
        else
          fail ArgumentError, "'#{str}' is not a valid clark-notation formatted string"
        end
      end
    end
  end
end
