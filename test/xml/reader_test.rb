require 'test_helper'
require 'xml/element/mock'
require 'xml/element/eater'

module Tilia
  module Xml
    class ReaderTest < Minitest::Test
      def setup
        @reader = Reader.new
      end

      def test_get_clark
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns" />
BLA
        @reader.xml(input)
        @reader.next
        assert_equal('{http://sabredav.org/ns}root', @reader.clark)
      end

      def test_get_clark_no_ns
        input = <<BLA
<?xml version="1.0"?>
<root />
BLA
        @reader.xml(input)
        @reader.next
        assert_equal('{}root', @reader.clark)
      end

      def test_get_clark_not_on_an_element
        input = <<BLA
<?xml version="1.0"?>
<root />
BLA
        @reader.xml(input)
        assert_nil(@reader.clark)
      end

      def test_simple
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <elem1 attr="val" />
  <elem2>
    <elem3>Hi!</elem3>
  </elem2>
</root>
BLA
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'       => '{http://sabredav.org/ns}elem1',
              'value'      => nil,
              'attributes' => {
                'attr' => 'val'
              }
            },
            {
              'name'  => '{http://sabredav.org/ns}elem2',
              'value' => [
                {
                  'name'       => '{http://sabredav.org/ns}elem3',
                  'value'      => 'Hi!',
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

      def test_cdata
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <foo><![CDATA[bar]]></foo>
</root>
BLA
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'       => '{http://sabredav.org/ns}foo',
              'value'      => 'bar',
              'attributes' => {}
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, output)
      end

      def test_simple_namespaced_attribute
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns" xmlns:foo="urn:foo">
  <elem1 foo:attr="val" />
</root>
BLA
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'       => '{http://sabredav.org/ns}elem1',
              'value'      => nil,
              'attributes' => {
                '{urn:foo}attr' => 'val'
              }
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, output)
      end

      def test_mapped_element
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <elem1 />
</root>
BLA
        @reader.element_map = {
          '{http://sabredav.org/ns}elem1' => Element::Mock
        }
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'       => '{http://sabredav.org/ns}elem1',
              'value'      => 'foobar',
              'attributes' => {}
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, output)
      end

      def test_mapped_element_bad_class
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <elem1 />
</root>
BLA

        reader = Reader.new
        reader.element_map = {
          '{http://sabredav.org/ns}elem1' => Class.new
        }
        reader.xml(input)

        assert_raises(RuntimeError) do
          reader.parse
        end
      end

      def test_mapped_element_call_back
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <elem1 />
</root>
BLA
        @reader.element_map = {
          '{http://sabredav.org/ns}elem1' => lambda do |reader|
            reader.next
            'foobar'
          end
        }
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'       => '{http://sabredav.org/ns}elem1',
              'value'      => 'foobar',
              'attributes' => {}
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, output)
      end

      def test_read_text
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <elem1>
    <elem2>hello </elem2>
    <elem2>world</elem2>
  </elem1>
</root>
BLA
        @reader.element_map = {
          '{http://sabredav.org/ns}elem1' => ->(reader) { reader.read_text }
        }
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'       => '{http://sabredav.org/ns}elem1',
              'value'      => 'hello world',
              'attributes' => {}
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, output)
      end

      def test_parse_problem
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
BLA
        @reader.element_map = {
          '{http://sabredav.org/ns}elem1' => Element::Mock
        }
        @reader.xml(input)

        assert_raises(LibXmlException) { @reader.parse }
      end

      def test_broken_parser_class
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
<elem1 />
</root>
BLA
        @reader.element_map = {
          '{http://sabredav.org/ns}elem1' => Element::Eater
        }
        @reader.xml(input)
        assert_raises(ParseException) { @reader.parse }
      end

      def test_broken_xml
        input = <<BLA
<test>
<hello>
</hello>
</sffsdf>
BLA
        @reader.xml(input)
        assert_raises(LibXmlException) { @reader.parse }
      end

      def test_broken_xml2
        input = <<BLA
<?xml version="1.0" encoding="UTF-8"?>
<definitions>
    <collaboration>
        <participant id="sid-A33D08EB-A2DE-448F-86FE-A2B62E98818" name="Company" processRef="sid-A0A6A196-3C9A-4C69-88F6-7ED7DDFDD264">
            <extensionElements>
                <signavio:signavioMetaData metaKey="bgcolor" />
                ""Administrative w">
                <extensionElements>
                    <signavio:signavioMetaData metaKey="bgcolor" metaValue=""/>
                </extensionElements>
                </lan
BLA
        @reader.xml(input)
        assert_raises(LibXmlException) { @reader.parse }
      end

      def test_parse_inner_tree
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <elem1>
     <elem1 />
  </elem1>
</root>
BLA
        @reader.element_map = {
          '{http://sabredav.org/ns}elem1' => lambda do |reader|
            inner_tree = reader.parse_inner_tree(
              '{http://sabredav.org/ns}elem1' => lambda do |lambda_reader|
                lambda_reader.next
                'foobar'
              end
            )
            inner_tree
          end
        }
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'  => '{http://sabredav.org/ns}elem1',
              'value' => [
                {
                  'name'       => '{http://sabredav.org/ns}elem1',
                  'value'      => 'foobar',
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

      def test_parse_get_elements
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <elem1>
     <elem1 />
  </elem1>
</root>
BLA
        @reader.element_map = {
          '{http://sabredav.org/ns}elem1' => lambda do |reader|
            inner_tree = reader.parse_get_elements(
              '{http://sabredav.org/ns}elem1' => lambda do |lambda_reader|
                lambda_reader.next
                'foobar'
              end
            )
            inner_tree
          end
        }
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'  => '{http://sabredav.org/ns}elem1',
              'value' => [
                {
                  'name'       => '{http://sabredav.org/ns}elem1',
                  'value'      => 'foobar',
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

      def test_parse_get_elements_no_elements
        input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <elem1>
    hi
  </elem1>
</root>
BLA
        @reader.element_map = {
          '{http://sabredav.org/ns}elem1' => lambda do |reader|
            inner_tree = reader.parse_get_elements(
              '{http://sabredav.org/ns}elem1' => lambda do |lambda_reader|
                lambda_reader.next
                'foobar'
              end
            )
            inner_tree
          end
        }
        @reader.xml(input)
        output = @reader.parse

        expected = {
          'name'  => '{http://sabredav.org/ns}root',
          'value' => [
            {
              'name'       => '{http://sabredav.org/ns}elem1',
              'value'      => [],
              'attributes' => {}
            }
          ],
          'attributes' => {}
        }

        assert_equal(expected, output)
      end
    end
  end
end
