require 'test_helper'

module Tilia
  module Xml
    class XmlFragmentTest < Minitest::Test
      # Data provider for serialize and deserialize tests.
      #
      # Returns three items per test:
      #
      # 1. Input data for the reader.
      # 2. Expected output for XmlFragment deserializer
      # 3. Expected output after serializing that value again.
      #
      # If 3 is not set, use 1 for 3.
      #
      # @return [Array]
      def xml_provider
        [
          [
            'hello',
            'hello'
          ],
          [
            '<element>hello</element>',
            '<element xmlns="http://sabredav.org/ns">hello</element>'
          ],
          [
            '<element foo="bar">hello</element>',
            '<element xmlns="http://sabredav.org/ns" foo="bar">hello</element>'
          ],
          [
            '<element x1:foo="bar" xmlns:x1="http://example.org/ns">hello</element>',
            '<element xmlns:x1="http://example.org/ns" xmlns="http://sabredav.org/ns" x1:foo="bar">hello</element>'
          ],
          [
            '<element xmlns="http://example.org/ns">hello</element>',
            '<element xmlns="http://example.org/ns">hello</element>',
            '<x1:element xmlns:x1="http://example.org/ns">hello</x1:element>'
          ],
          [
            '<element xmlns:foo="http://example.org/ns">hello</element>',
            '<element xmlns:foo="http://example.org/ns" xmlns="http://sabredav.org/ns">hello</element>',
            '<element>hello</element>'
          ],
          [
            '<foo:element xmlns:foo="http://example.org/ns">hello</foo:element>',
            '<foo:element xmlns:foo="http://example.org/ns">hello</foo:element>',
            '<x1:element xmlns:x1="http://example.org/ns">hello</x1:element>'
          ],
          [
            '<foo:element xmlns:foo="http://example.org/ns"><child>hello</child></foo:element>',
            '<foo:element xmlns:foo="http://example.org/ns" xmlns="http://sabredav.org/ns"><child>hello</child></foo:element>',
            '<x1:element xmlns:x1="http://example.org/ns"><child>hello</child></x1:element>'
          ],
          [
            '<foo:element xmlns:foo="http://example.org/ns"><child/></foo:element>',
            '<foo:element xmlns:foo="http://example.org/ns" xmlns="http://sabredav.org/ns"><child/></foo:element>',
            '<x1:element xmlns:x1="http://example.org/ns"><child/></x1:element>'
          ],
          [
            '<foo:element xmlns:foo="http://example.org/ns"><child a="b"/></foo:element>',
            '<foo:element xmlns:foo="http://example.org/ns" xmlns="http://sabredav.org/ns"><child a="b"/></foo:element>',
            '<x1:element xmlns:x1="http://example.org/ns"><child a="b"/></x1:element>'
          ]
        ]
      end

      def test_deserialize
        xml_provider.each do |data|
          (input, expected) = data
          input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
   <fragment>#{input}</fragment>
</root>
BLA
          reader = Tilia::Xml::Reader.new
          reader.element_map = { '{http://sabredav.org/ns}fragment' => Tilia::Xml::Element::XmlFragment }
          reader.xml(input)
          output = reader.parse

          result = {
            'name'  => '{http://sabredav.org/ns}root',
            'value' => [
              {
                'name'       => '{http://sabredav.org/ns}fragment',
                'value'      => Tilia::Xml::Element::XmlFragment.new(expected),
                'attributes' => {}
              }
            ],
            'attributes' => {}
          }
          assert_equal(result, output)
        end
      end

      def test_serialize
        xml_provider.each do |data|
          (expected_fallback, input, expected) = data

          expected = expected_fallback if expected.nil?

          writer = Tilia::Xml::Writer.new
          writer.namespace_map = { 'http://sabredav.org/ns' => nil }
          writer.open_memory
          writer.start_document
          writer.write('{http://sabredav.org/ns}root' => { '{http://sabredav.org/ns}fragment' => Tilia::Xml::Element::XmlFragment.new(input) })
          output = writer.output_memory

          result = <<XML
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns"><fragment>#{expected}</fragment></root>
XML
          result.chomp!

          assert_equal(result, output)
        end
      end
    end
  end
end
