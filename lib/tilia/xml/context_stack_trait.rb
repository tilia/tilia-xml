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

      # @!attribute [r] _context_stack
      #   @!visibility private
      #
      # Backups of previous contexts.
      #
      # @return [Array]

      # Create a new "context".
      #
      # This allows you to safely modify the element_map, context_uri or
      # namespace_map. After you're done, you can restore the old data again
      # with popContext.
      #
      # @return [void]
      def push_context
        dup_or_obj = lambda do |obj|
          if obj.nil?
            nil
          elsif obj.is_a? Fixnum
            obj
          else
            obj.dup
          end
        end

        @context_stack << [
          dup_or_obj.call(@element_map),
          dup_or_obj.call(@context_uri),
          dup_or_obj.call(@namespace_map)
        ]
      end

      # Restore the previous "context".
      #
      # @return [void]
      def pop_context
        (
          @element_map,
          @context_uri,
          @namespace_map
        ) = @context_stack.pop
      end

      # Initializes instance variables
      def initialize_context_stack_attributes
        @element_map = {}
        @namespace_map = {}
        @context_uri = ''
        @context_stack = []
      end
    end
  end
end
