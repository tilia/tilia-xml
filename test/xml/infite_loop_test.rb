require 'test_helper'

module Tilia
  module Xml
    class InfiteLoopTest < Minitest::Test
      # This particular xml body caused the parser to go into an infinite loop.
      # Need to know why.
      def test_deserialize
        body = <<XML
<?xml version="1.0"?>
<d:propertyupdate xmlns:d="DAV:" xmlns:s="http://sabredav.org/NS/test">
  <d:set><d:prop></d:prop></d:set>
  <d:set><d:prop></d:prop></d:set>
</d:propertyupdate>
XML
        reader = Reader.new
        reader.element_map = { '{DAV:}set' => Element::KeyValue }
        reader.xml(body)

        output = reader.parse

        expected = {
          'name'  => '{DAV:}propertyupdate',
          'value' => [
            {
              'name'  => '{DAV:}set',
              'value' => {
                '{DAV:}prop' => nil
              },
              'attributes' => {}
            },
            {
              'name'  => '{DAV:}set',
              'value' => {
                '{DAV:}prop' => nil
              },
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
