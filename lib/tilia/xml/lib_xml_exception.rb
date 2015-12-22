module Tilia
  module Xml
    # This exception is thrown when the Readers runs into a parsing error.
    #
    # This exception effectively wraps 1 or more LibXMLError objects.
    class LibXmlException < ParseException
    end
  end
end
