module Tilia
  module Xml
    module Element
      # The Base XML element is the standard parser & generator that's used by the
      # XML reader and writer.
      #
      # It spits out a simple PHP array structure during deserialization, that can
      # also be directly injected back into Writer::write.
      class Base
        include Element

        # Constructor
        #
        # @param value
        def initialize(value = nil)
          @value = value
        end

        # (see XmlSerializable#xml_serialize)
        def xml_serialize(writer)
          writer.write(@value)
        end

        # (see XmlDeserializable#xml_deserialize)
        def self.xml_deserialize(reader)
          sub_tree = reader.parse_inner_tree
          sub_tree
        end
      end
    end
  end
end
