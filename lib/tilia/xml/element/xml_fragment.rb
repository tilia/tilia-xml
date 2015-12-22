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

        protected

        attr_accessor :xml

        public

        def initialize(xml)
          @xml = xml
        end

        # get_xml replaced by xml

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

        # The deserialize method is called during xml parsing.
        #
        # This method is called statictly, this is because in theory this method
        # may be used as a type of constructor, or factory method.
        #
        # Often you want to return an instance of the current class, but you are
        # free to return other data as well.
        #
        # You are responsible for advancing the reader to the next element. Not
        # doing anything will result in a never-ending loop.
        #
        # If you just want to skip parsing for this element altogether, you can
        # just call reader->next();
        #
        # reader->parseInnerTree() will parse the entire sub-tree, and advance to
        # the next element.
        #
        # @param [Reader] reader
        # @return mixed
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
