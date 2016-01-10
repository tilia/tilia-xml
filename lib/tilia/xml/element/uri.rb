module Tilia
  module Xml
    module Element
      # Uri element.
      #
      # This represents a single uri. An example of how this may be encoded:
      #
      #    <link>/foo/bar</link>
      #    <d:href xmlns:d="DAV:">http://example.org/hi</d:href>
      #
      # If the uri is relative, it will be automatically expanded to an absolute
      # url during writing and reading, if the contextUri property is set on the
      # reader and/or writer.
      class Uri
        include Element

        # @!attribute [r] _value
        #   @!visibility private
        #
        # Uri element value.
        #
        # @return [String]

        # Constructor
        #
        # @param [String] value
        def initialize(value)
          @value = value
        end

        # The xml_serialize metod is called during xml writing.
        #
        # Use the writer argument to write its own xml serialization.
        #
        # An important note: do _not_ create a parent element. Any element
        # implementing XmlSerializble should only ever write what's considered
        # its 'inner xml'.
        #
        # The parent of the current element is responsible for writing a
        # containing element.
        #
        # This allows serializers to be re-used for different element names.
        #
        # If you are opening new elements, you must also close them again.
        #
        # @param [Writer] writer
        # @return [void]
        def xml_serialize(writer)
          writer.write_string(
            ::Tilia::Uri.resolve(
              writer.context_uri,
              @value
            )
          )
        end

        # This method is called during xml parsing.
        #
        # This method is called statically, this is because in theory this method
        # may be used as a type of constructor, or factory method.
        #
        # Often you want to return an instance of the current class, but you are
        # free to return other data as well.
        #
        # Important note 2: You are responsible for advancing the reader to the
        # next element. Not doing anything will result in a never-ending loop.
        #
        # If you just want to skip parsing for this element altogether, you can
        # just call reader->next();
        #
        # reader->parseSubTree() will parse the entire sub-tree, and advance to
        # the next element.
        #
        # @param [Reader] reader
        # @return mixed
        def self.xml_deserialize(reader)
          new(
            ::Tilia::Uri.resolve(
              reader.context_uri,
              reader.read_text
            )
          )
        end

        # TODO: document
        def ==(other)
          if other.is_a? self.class
            other.instance_eval { @value } == @value
          else
            false
          end
        end
      end
    end
  end
end
