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

        # Constructor
        #
        # @param [String] value
        def initialize(value)
          @value = value
        end

        # (see XmlSerializable#xml_serialize)
        def xml_serialize(writer)
          writer.write_string(
            ::Tilia::Uri.resolve(
              writer.context_uri,
              @value
            )
          )
        end

        # (see XmlDeserializable#xml_deserialize)
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
