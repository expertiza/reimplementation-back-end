# frozen_string_literal: true

class Hash
  # More descriptive alias for transform_values used when collapsing weighted
  # accumulators ({ sum:, weight: } buckets) into their final averages.
  alias_method :average_weighted_sums, :transform_values
end
