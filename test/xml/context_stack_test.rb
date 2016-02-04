require 'test_helper'

module Tilia
  module Xml
    class ContextStackTest < Minitest::Test
      def setup
        @stack = ContextStackMock.new
      end

      def test_push_and_pull
        @stack.context_uri = '/foo/bar'
        @stack.element_map['{DAV:}foo'] = 'Bar'
        @stack.namespace_map['DAV:'] = 'd'

        @stack.push_context

        assert_equal('/foo/bar', @stack.context_uri)
        assert_equal('Bar', @stack.element_map['{DAV:}foo'])
        assert_equal('d', @stack.namespace_map['DAV:'])

        @stack.context_uri = '/gir/zim'
        @stack.element_map['{DAV:}foo'] = 'newBar'
        @stack.namespace_map['DAV:'] = 'dd'

        @stack.pop_context

        assert_equal('/foo/bar', @stack.context_uri)
        assert_equal('Bar', @stack.element_map['{DAV:}foo'])
        assert_equal('d', @stack.namespace_map['DAV:'])
      end
    end

    class ContextStackMock
      include ContextStackTrait
    end
  end
end
