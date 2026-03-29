# frozen_string_literal: true

# AMS expects Hash-like options (with #fetch) in several places. Adapter::Base#serialization_options
# only runs for the JSON adapter's inner path; ActiveModel::Serializer::CollectionSerializer does not
# inherit Adapter::Base and calls options.fetch in #serializers_from_resources.
# If a model instance is ever passed where options were expected, we get:
#   NoMethodError: undefined method 'fetch' for an instance of User
module AmsSerializationOptionsCoercion
  module_function

  def coerce(value)
    return {} if value.nil?
    return {} if defined?(ActiveRecord::Base) && value.is_a?(ActiveRecord::Base)
    return value if value.respond_to?(:fetch)

    {}
  end
end

# JSON adapter path (Attributes -> serializer)
module ActiveModelSerializers
  module Adapter
    module CoerceAdapterSerializationOptions
      private

      def serialization_options(options)
        super(AmsSerializationOptionsCoercion.coerce(options))
      end
    end

    class Base
      prepend CoerceAdapterSerializationOptions
    end
  end
end

module ActiveModel
  class Serializer
    module CoerceSerializableHashOptions
      def serializable_hash(adapter_options = nil, options = {}, adapter_instance = self.class.serialization_adapter_instance)
        super(
          AmsSerializationOptionsCoercion.coerce(adapter_options),
          AmsSerializationOptionsCoercion.coerce(options),
          adapter_instance
        )
      end
    end

    prepend CoerceSerializableHashOptions

    class CollectionSerializer
      module CoerceCollectionSerializerOptions
        def initialize(resources, options = {})
          super(resources, AmsSerializationOptionsCoercion.coerce(options))
        end

        def serializable_hash(adapter_options, options, adapter_instance)
          super(
            AmsSerializationOptionsCoercion.coerce(adapter_options),
            AmsSerializationOptionsCoercion.coerce(options),
            adapter_instance
          )
        end
      end

      prepend CoerceCollectionSerializerOptions
    end
  end
end
