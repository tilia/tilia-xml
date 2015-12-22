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
      # @param [String, nil] root_element_name
      # @raise [ParseException]
      # @return [Array, Object, String]
      def parse(input, context_uri = nil, root_element_name = nil)
        # Skip php short commings
        reader = self.reader
        reader.context_uri = context_uri
        reader.xml(input)

        result = reader.parse
        root_element_name.replace(result['name'])
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
      # @param [String] root_element_name
      # @param [String, File, StringIO] input
      # @param [String, nil] context_uri
      # @return [void]
      def expect(root_element_name, input, context_uri = nil)
        # Skip php short commings
        reader = self.reader
        reader.context_uri = context_uri
        reader.xml(input)

        result = reader.parse
        if root_element_name != result['name']
          fail Tilia::Xml::ParseException, "Expected #{root_element_name} but received #{result['name']} as the root element"
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

      # Parses a clark-notation string, and returns the namespace and element
      # name components.
      #
      # If the string was invalid, it will throw an InvalidArgumentException.
      #
      # @param [String] str
      # @raise [InvalidArgumentException]
      # @return [Array]
      def self.parse_clark_notation(str)
        if str =~ /^{([^}]*)}(.*)/
          [Regexp.last_match[1], Regexp.last_match[2]]
        else
          fail ArgumentError, "'#{str}' is not a valid clark-notation formatted string"
        end
      end

      # TODO: document
      def initialize
        @element_map = {}
        @namespace_map = {}
      end
    end
  end
end
