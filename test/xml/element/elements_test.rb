require 'test_helper'

module Tilia
  module Xml
    class ElementsTest < Minitest::Test
      def test_deserialize
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <listThingy>
    <elem1 />
    <elem2 />
    <elem3 />
    <elem4 attr="val" />
    <elem5>content</elem5>
    <elem6><subnode /></elem6>
  </listThingy>
  <listThingy />
  <otherThing>
    <elem1 />
    <elem2 />
    <elem3 />
  </otherThing>
</root>
BLA
        reader = Reader.new
        reader.element_map = { '{http://sabredav.org/ns}listThingy' => Element::Elements }
        reader.xml(input)

        output = reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'  => '{http://sabredav.org/ns}listThingy',
              'value' => [
                '{http://sabredav.org/ns}elem1',
                '{http://sabredav.org/ns}elem2',
                '{http://sabredav.org/ns}elem3',
                '{http://sabredav.org/ns}elem4',
                '{http://sabredav.org/ns}elem5',
                '{http://sabredav.org/ns}elem6'
              ],
              'attributes' => {}
            },
            {
              'name'       => '{http://sabredav.org/ns}listThingy',
              'value'      => [],
              'attributes' => {}
            },
            {
              'name'  => '{http://sabredav.org/ns}otherThing',
              'value' => [
                {
                  'name'       => '{http://sabredav.org/ns}elem1',
                  'value'      => nil,
                  'attributes' => {}
                },
                {
                  'name'       => '{http://sabredav.org/ns}elem2',
                  'value'      => nil,
                  'attributes' => {}
                },
                {
                  'name'       => '{http://sabredav.org/ns}elem3',
                  'value'      => nil,
                  'attributes' => {}
                }
              ],
              'attributes' => {}
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, output)
      end

      def test_serialize
        value = [
          '{http://sabredav.org/ns}elem1',
          '{http://sabredav.org/ns}elem2',
          '{http://sabredav.org/ns}elem3',
          '{http://sabredav.org/ns}elem4',
          '{http://sabredav.org/ns}elem5',
          '{http://sabredav.org/ns}elem6'
        ]

        writer = Writer.new
        writer.namespace_map = { 'http://sabredav.org/ns' => nil }
        writer.open_memory
        writer.start_document
        writer.set_indent(true)
        writer.write('{http://sabredav.org/ns}root' => Element::Elements.new(value))
        output = writer.output_memory

        expected = <<XML
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
 <elem1/>
 <elem2/>
 <elem3/>
 <elem4/>
 <elem5/>
 <elem6/>
</root>
XML
        assert_equal(expected, output)
      end
    end
  end
end
