require 'test_helper'
require 'stringio'

module Tilia
  module Xml
    class WriterTest < Minitest::Test
      def setup
        @writer = Tilia::Xml::Writer.new
        @writer.namespace_map = { 'http://sabredav.org/ns' => 's' }
        @writer.open_memory
        @writer.set_indent(true)
        @writer.start_document
      end

      def compare(input, output)
        @writer.write(input)
        assert_equal(output, @writer.output_memory)
      end

      def test_simple
        compare(
          { '{http://sabredav.org/ns}root' => 'text' },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">text</s:root>
HI
        )
      end

      def test_simple_quotes
        compare(
          { '{http://sabredav.org/ns}root' => '"text"' },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">&quot;text&quot;</s:root>
HI
        )
      end

      def test_simple_attributes
        compare(
          {
            '{http://sabredav.org/ns}root' => {
              'value'      => 'text',
              'attributes' => {
                'attr1' => 'attribute value'
              }
            }
          },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns" attr1="attribute value">text</s:root>
HI
        )
      end

      def test_mixed_syntax
        compare(
          {
            '{http://sabredav.org/ns}root' => {
              'single'   => 'value',
              'multiple' => [
                {
                  'name'  => 'foo',
                  'value' => 'bar'
                },
                {
                  'name'  => 'foo',
                  'value' => 'foobar'
                }
              ],
              'attributes' => {
                'value'      => nil,
                'attributes' => {
                  'foo' => 'bar'
                }
              },
              'verbose' => { # RUBY
                # 'name'       => 'verbose', # RUBY
                'value'      => 'syntax',
                'attributes' => {
                  'foo' => 'bar'
                }
              }
            }
          },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">
 <single>value</single>
 <multiple>
  <foo>bar</foo>
  <foo>foobar</foo>
 </multiple>
 <attributes foo="bar"/>
 <verbose foo="bar">syntax</verbose>
</s:root>
HI
        )
      end

      def test_null
        compare(
          { '{http://sabredav.org/ns}root' => nil },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns"/>
HI
        )
      end

      def test_array_format2
        compare(
          {
            '{http://sabredav.org/ns}root' => [
              {
                'name'       => '{http://sabredav.org/ns}elem1',
                'value'      => 'text',
                'attributes' => {
                  'attr1' => 'attribute value'
                }
              }
            ]
          },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">
 <s:elem1 attr1="attribute value">text</s:elem1>
</s:root>
HI
        )
      end

      def test_array_format2_no_value
        compare(
          {
            '{http://sabredav.org/ns}root' => [
              {
                'name'       => '{http://sabredav.org/ns}elem1',
                'attributes' => {
                  'attr1' => 'attribute value'
                }
              }
            ]
          },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">
 <s:elem1 attr1="attribute value"/>
</s:root>
HI
        )
      end

      def test_custom_namespace
        compare(
          {
            '{http://sabredav.org/ns}root' => {
              '{urn:foo}elem1' => 'bar'
            }
          },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">
 <x1:elem1 xmlns:x1="urn:foo">bar</x1:elem1>
</s:root>
HI
        )
      end

      def test_empty_namespace
        # Empty namespaces are allowed, so we should support this.
        compare(
          { '{http://sabredav.org/ns}root' => { '{}elem1' => 'bar' } },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">
 <elem1 xmlns="">bar</elem1>
</s:root>
HI
        )
      end

      def test_attributes
        compare(
          {
            '{http://sabredav.org/ns}root' => [
              {
                'name'       => '{http://sabredav.org/ns}elem1',
                'value'      => 'text',
                'attributes' => {
                  'attr1'                         => 'val1',
                  '{http://sabredav.org/ns}attr2' => 'val2',
                  '{urn:foo}attr3'                => 'val3'
                }
              }
            ]
          },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">
 <s:elem1 attr1="val1" s:attr2="val2" x1:attr3="val3" xmlns:x1="urn:foo">text</s:elem1>
</s:root>
HI
        )
      end

      def test_invalid_format
        assert_raises(ArgumentError) do
          compare(
            {
              '{http://sabredav.org/ns}root' => [
                { 'incorrect' => '0', 'keynames' => 1 }
              ]
            },
            ''
          )
        end
      end

      def test_base_element
        compare(
          { '{http://sabredav.org/ns}root' => Tilia::Xml::Element::Base.new('hello') },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">hello</s:root>
HI
        )
      end

      def test_element_obj
        compare(
          { '{http://sabredav.org/ns}root' => Tilia::Xml::Element::Mock.new },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">
 <s:elem1>hiiii!</s:elem1>
</s:root>
HI
        )
      end

      def test_empty_namespace_prefix
        @writer.namespace_map['http://sabredav.org/ns'] = nil
        compare(
          { '{http://sabredav.org/ns}root' => Tilia::Xml::Element::Mock.new },
          <<HI
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
 <elem1>hiiii!</elem1>
</root>
HI
        )
      end

      def test_empty_namespace_prefix_empty_string
        @writer.namespace_map['http://sabredav.org/ns'] = ''
        compare(
          { '{http://sabredav.org/ns}root' => Element::Mock.new },
          <<HI
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
 <elem1>hiiii!</elem1>
</root>
HI
        )
      end

      def test_write_element
        @writer.write_element('{http://sabredav.org/ns}foo', 'content')

        output = <<HI
<?xml version="1.0"?>
<s:foo xmlns:s="http://sabredav.org/ns">content</s:foo>
HI
        assert_equal(output, @writer.output_memory)
      end

      def test_write_element_complex
        @writer.write_element('{http://sabredav.org/ns}foo', Tilia::Xml::Element::KeyValue.new('{http://sabredav.org/ns}bar' => 'test'))

        output = <<HI
<?xml version="1.0"?>
<s:foo xmlns:s="http://sabredav.org/ns">
 <s:bar>test</s:bar>
</s:foo>
HI
        assert_equal(output, @writer.output_memory)
      end

      def test_write_bad_object
        assert_raises(ArgumentError) { @writer.write(Class.new) }
      end

      def test_start_element_simple
        @writer.start_element('foo')
        @writer.end_element

        output = <<HI
<?xml version="1.0"?>
<foo xmlns:s="http://sabredav.org/ns"/>
HI
        assert_equal(output, @writer.output_memory)
      end

      def test_callback
        compare(
          {
            '{http://sabredav.org/ns}root' => lambda do |writer|
              writer.write_string('deferred writer')
            end
          },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">deferred writer</s:root>
HI
        )
      end

      def test_resource
        assert_raises(ArgumentError) do
          compare(
            { '{http://sabredav.org/ns}root' => StringIO.new },
            <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">deferred writer</s:root>
HI
          )
        end
      end

      def test_class_map
        obj = TestClass.new('value1', 'value2')

        @writer.class_map[TestClass] = lambda do |writer, value|
          [:@key1, :@key2].each do |key|
            val = value.instance_variable_get(key)
            key = key.to_s[1..-1]
            writer.write_element("{http://sabredav.org/ns}#{key}", val)
          end
        end

        compare(
          { '{http://sabredav.org/ns}root' => obj },
          <<HI
<?xml version="1.0"?>
<s:root xmlns:s="http://sabredav.org/ns">
 <s:key1>value1</s:key1>
 <s:key2>value2</s:key2>
</s:root>
HI
        )
      end
    end

    class TestClass
      def initialize(a, b)
        @key1 = a
        @key2 = b
      end
    end
  end
end
