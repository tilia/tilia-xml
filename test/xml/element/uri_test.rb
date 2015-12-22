require 'test_helper'

module Tilia
  module Xml
    class UriTest < Minitest::Test
      def test_deserialize
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <uri>/foo/bar</uri>
</root>
BLA
        reader = Tilia::Xml::Reader.new
        reader.context_uri = 'http://example.org/'
        reader.element_map = { '{http://sabredav.org/ns}uri' => Tilia::Xml::Element::Uri }
        reader.xml(input)
        output = reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'       => '{http://sabredav.org/ns}uri',
              'value'      => Tilia::Xml::Element::Uri.new('http://example.org/foo/bar'),
              'attributes' => {}
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, output)
      end

      def test_serialize
        writer = Tilia::Xml::Writer.new
        writer.namespace_map = { 'http://sabredav.org/ns' => nil }
        writer.open_memory
        writer.start_document
        writer.set_indent(true)
        writer.context_uri = 'http://example.org/'
        writer.write('{http://sabredav.org/ns}root' => { '{http://sabredav.org/ns}uri' => Tilia::Xml::Element::Uri.new('/foo/bar') })
        output = writer.output_memory

        expected = <<XML
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
 <uri>http://example.org/foo/bar</uri>
</root>
XML

        assert_equal(expected, output)
      end
    end
  end
end
