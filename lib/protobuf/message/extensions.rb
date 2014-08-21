module Protobuf
  class Message
    class Extensions
      def initialize(extension_fields)
        @field_store = {}

        extension_fields.each do |extension_field|
          @field_store[]
        end
      end

      def [](name)
        
      end

      def []=(name, value)
      end
    end
  end
end