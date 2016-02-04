module Tilia
  module Xml
    # Context Stack
    #
    # The Context maintains information about a document during either reading or
    # writing.
    #
    # During this process, it may be neccesary to override this context
    # information.
    #
    # This trait allows easy access to the context, and allows the end-user to
    # override its settings for document fragments, and easily restore it again
    # later.
    module ContextStackTrait
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

      # A context_uri pointing to the document being parsed / written.
      # This uri may be used to resolve relative urls that may appear in the
      # document.
      #
      # The reader and writer don't use this property, but as it's an extremely
      # common use-case for parsing XML documents, it's added here as a
      # convenience.
      #
      # @return [String]
      attr_accessor :context_uri

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

      # Create a new "context".
      #
      # This allows you to safely modify the element_map, context_uri or
      # namespace_map. After you're done, you can restore the old data again
      # with popContext.
      #
      # @return [void]
      def push_context
        @context_stack << [
          @element_map.deep_dup,
          @context_uri.deep_dup,
          @namespace_map.deep_dup,
          @class_map.deep_dup
        ]
      end

      # Restore the previous "context".
      #
      # @return [void]
      def pop_context
        (
          @element_map,
          @context_uri,
          @namespace_map,
          @class_map
        ) = @context_stack.pop
      end

      # Initializes instance variables
      def initialize(*args)
        @element_map = {}
        @namespace_map = {}
        @context_uri = ''
        @context_stack = []
        @class_map = {}

        super
      end
    end
  end
end
