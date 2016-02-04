require 'test_helper'

module Tilia
  module Xml
    module Deserializer
      class KeyValueTest < Minitest::Test
        def test_key_value

          input = <<BLA
<?xml version="1.0"?>
<root xmlns="http://sabredav.org/ns">
  <struct>
    <elem1 />
    <elem2>hi</elem2>
    <elem3 xmlns="http://sabredav.org/another-ns">
       <elem4>foo</elem4>
       <elem5>foo &amp; bar</elem5>
    </elem3>
  </struct>
</root>
BLA

          reader = Reader.new
          reader.element_map = {
            '{http://sabredav.org/ns}struct' => lambda do |reader|
              return Deserializer.key_value(reader, 'http://sabredav.org/ns')
            end
          }
          reader.xml(input)
          output = reader.parse

          assert_equal(
            {
              'name'  => '{http://sabredav.org/ns}root',
              'value' => [
                {
                  'name'  => '{http://sabredav.org/ns}struct',
                  'value' => {
                    'elem1'                                 => nil,
                    'elem2'                                 => 'hi',
                    '{http://sabredav.org/another-ns}elem3' => [
                      {
                        'name'       => '{http://sabredav.org/another-ns}elem4',
                        'value'      => 'foo',
                        'attributes' => {},
                      },
                      {
                        'name'       => '{http://sabredav.org/another-ns}elem5',
                        'value'      => 'foo & bar',
                        'attributes' => {},
                      },
                    ]
                  },
                  'attributes' => {},
                }
              ],
              'attributes' => {},
            },
            output
          )
        end
      end
    end
  end
end
