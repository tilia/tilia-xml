require 'test_helper'

module Tilia
  module Xml
    class KeyValueTest < Minitest::Test
      def test_deserialize
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <struct>
    <elem1 />
    <elem2>hi</elem2>
    <elem3>
       <elem4>foo</elem4>
       <elem5>foo &amp; bar</elem5>
    </elem3>
    <elem6>Hi<!-- ignore me -->there</elem6>
  </struct>
  <struct />
  <otherThing>
    <elem1 />
  </otherThing>
</root>
BLA

        reader = Tilia::Xml::Reader.new
        reader.element_map = { '{http://sabredav.org/ns}struct' => Tilia::Xml::Element::KeyValue }
        reader.xml(input)

        output = reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'  => '{http://sabredav.org/ns}struct',
              'value' => {
                '{http://sabredav.org/ns}elem1' => nil,
                '{http://sabredav.org/ns}elem2' => 'hi',
                '{http://sabredav.org/ns}elem3' => [
                  {
                    'name'       => '{http://sabredav.org/ns}elem4',
                    'value'      => 'foo',
                    'attributes' => {}
                  },
                  {
                    'name'       => '{http://sabredav.org/ns}elem5',
                    'value'      => 'foo & bar',
                    'attributes' => {}
                  }
                ],
                '{http://sabredav.org/ns}elem6' => 'Hithere'
              },
              'attributes' => {}
            },
            {
              'name'       => '{http://sabredav.org/ns}struct',
              'value'      => {},
              'attributes' => {}
            },
            {
              'name'  => '{http://sabredav.org/ns}otherThing',
              'value' => [
                {
                  'name'       => '{http://sabredav.org/ns}elem1',
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

      # This test was added to find out why an element gets eaten by the
      # SabreDAV MKCOL parser.
      def test_element_eater
        input = <<BLA
<?xml version="1.0"?>
<mkcol xmlns="DAV:">
  <set>
    <prop>
        <resourcetype><collection /></resourcetype>
        <displayname>bla</displayname>
    </prop>
  </set>
</mkcol>
BLA

        reader = Tilia::Xml::Reader.new
        reader.element_map = {
          '{DAV:}set'          => Tilia::Xml::Element::KeyValue,
          '{DAV:}prop'         => Tilia::Xml::Element::KeyValue,
          '{DAV:}resourcetype' => Tilia::Xml::Element::Elements
        }
        reader.xml(input)

        expected = {
          'name'  => '{DAV:}mkcol',
          'value' => [
            {
              'name'  => '{DAV:}set',
              'value' => {
                '{DAV:}prop' => {
                  '{DAV:}resourcetype' => [
                    '{DAV:}collection'
                  ],
                  '{DAV:}displayname' => 'bla'
                }
              },
              'attributes' => {}
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, reader.parse)
      end

      def test_serialize
        value = {
          '{http://sabredav.org/ns}elem1' => nil,
          '{http://sabredav.org/ns}elem2' => 'textValue',
          '{http://sabredav.org/ns}elem3' => {
            '{http://sabredav.org/ns}elem4' => 'text2',
            '{http://sabredav.org/ns}elem5' => nil
          },
          '{http://sabredav.org/ns}elem6' => 'text3'
        }

        writer = Tilia::Xml::Writer.new
        writer.namespace_map = { 'http://sabredav.org/ns' => nil }
        writer.open_memory
        writer.start_document
        writer.set_indent(true)
        writer.write('{http://sabredav.org/ns}root' => Tilia::Xml::Element::KeyValue.new(value))
        output = writer.output_memory

        expected = <<XML
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
 <elem1/>
 <elem2>textValue</elem2>
 <elem3>
  <elem4>text2</elem4>
  <elem5/>
 </elem3>
 <elem6>text3</elem6>
</root>
XML
        assert_equal(expected, output)
      end

      # I discovered that when there's no whitespace between elements, elements
      # can get skipped.
      def test_element_skip_problem
        input = <<BLA
<?xml version="1.0" encoding="utf-8"?>
<root xmlns="http://sabredav.org/ns">
<elem3>val3</elem3><elem4>val4</elem4><elem5>val5</elem5></root>
BLA

        reader = Tilia::Xml::Reader.new
        reader.element_map = { '{http://sabredav.org/ns}root' => Tilia::Xml::Element::KeyValue }
        reader.xml(input)

        output = reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => {
            '{http://sabredav.org/ns}elem3' => 'val3',
            '{http://sabredav.org/ns}elem4' => 'val4',
            '{http://sabredav.org/ns}elem5' => 'val5'
          },
          'attributes' => {}
        }

        assert_equal(expected, output)
      end
    end
  end
end
