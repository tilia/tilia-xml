module Tilia
  module Xml
    module Element
      # The XmlFragment element allows you to extract a portion of your xml tree,
      # and get a well-formed xml string.
      #
      # This goes a bit beyond `innerXml` and friends, as we'll also match all the
      # correct namespaces.
      #
      # Please note that the XML fragment:
      #
      # 1. Will not have an <?xml declaration.
      # 2. Or a DTD
      # 3. It will have all the relevant xmlns attributes.
      # 4. It may not have a root element.
      class XmlFragment
        include Element

        def initialize(xml)
          @xml = xml
        end

        attr_reader :xml

        # (see XmlSerializable#xml_serialize)
        def xml_serialize(writer)
          reader = Reader.new

          # Wrapping the xml in a container, so root-less values can still be
          # parsed.
          xml = <<XML
<?xml version="1.0"?>
<xml-fragment xmlns="http://sabre.io/ns">#{@xml}</xml-fragment>
XML

          reader.xml(xml)

          while reader.read
            if reader.depth < 1
              # Skipping the root node.
              next
            end

            case reader.node_type
            when ::LibXML::XML::Reader::TYPE_ELEMENT
              writer.start_element(reader.clark)
              empty = reader.empty_element?

              while reader.move_to_next_attribute != 0
                case reader.namespace_uri
                when '', nil # RUBY namespace_uri = nil ...
                  writer.write_attribute(reader.local_name, reader.value)
                when 'http://www.w3.org/2000/xmlns/'
                  # Skip namespace declarations
                else
                  writer.write_attribute(reader.clark, reader.value)
                end
              end

              writer.end_element if empty
            when ::LibXML::XML::Reader::TYPE_CDATA,
                ::LibXML::XML::Reader::TYPE_TEXT
              writer.write_string(reader.value)
            when ::LibXML::XML::Reader::TYPE_END_ELEMENT
              writer.end_element
            end
          end
        end

        # (see XmlDeserializable#xml_deserialize)
        def self.xml_deserialize(reader)
          result = new(reader.read_inner_xml)
          reader.next
          result
        end

        # TODO: document
        def ==(other)
          if other.is_a? self.class
            other.xml == @xml
          else
            false
          end
        end
      end
    end
  end
end
