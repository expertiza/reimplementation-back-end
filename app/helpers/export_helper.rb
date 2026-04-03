# frozen_string_literal: true

require 'set'

module ExportHelper
  module_function

  # Builds a minimal recursive graph with only class names and headers,
  # then returns one export payload per unique class in that graph.
  # traverses all the has_many and belongs_to descendants of the model provided.
  def export_has_many_graph(root_class)
    graph = build_export_graph(root_class)

    headers_by_class = {}
    each_graph_node_for_export(graph) do |node, headers_for_export|
      class_name = node[:class_name]
      headers_by_class[class_name] ||= []
      headers_by_class[class_name] |= headers_for_export
    end

    exports = []
    headers_by_class.each do |class_name, headers|
      exports.concat(Export.perform(class_name.constantize, headers, graph_export: false))
    end

    exports
  end

  # Recursively builds an export graph for the class and its related children.
  def build_export_graph(root_class, visited = Set.new)
    klass = normalize_class(root_class)
    class_name = klass.name

    if visited.include?(class_name)
      return {
        class_name: class_name,
        headers: mandatory_headers_for(klass),
        cyclic_reference: true,
        has_many: []
      }
    end

    visited.add(class_name)

    children = []

    # get has_many models
    klass.reflect_on_all_associations(:has_many).each do |association|
      begin
        child_klass = association.klass
      rescue StandardError
        next
      end

      children << build_export_graph(child_klass, visited)
    end

    # get belongs_to models
    descendants_with_belongs_to_parent(klass).each do |child_klass|
      children << build_export_graph(child_klass, visited)
    end

    {
      class_name: class_name,
      headers: mandatory_headers_for(klass),
      has_many: dedupe_children(children)
    }
  end

  # Finds descendant models that point back to the parent through a belongs_to association.
  def descendants_with_belongs_to_parent(parent_klass)
    descendants = ActiveRecord::Base.descendants.select { |model| model < ApplicationRecord }

    descendants.select do |candidate|
      next false if candidate == parent_klass

      candidate.reflect_on_all_associations(:belongs_to).any? do |belongs_to_association|
        begin
          belongs_to_association.klass == parent_klass || parent_klass <= belongs_to_association.klass
        rescue StandardError
          false
        end
      end
    end
  end
  private_class_method :descendants_with_belongs_to_parent

  # Removes duplicate child nodes so each class appears only once per level.
  def dedupe_children(children)
    children.uniq { |child| child[:class_name] }
  end
  private_class_method :dedupe_children

  # Walks each unique node in the graph once and yields it to the caller.
  def each_graph_node(graph, seen = Set.new, &block)
    return if seen.include?(graph[:class_name])

    seen.add(graph[:class_name])
    block.call(graph)

    graph[:has_many].each do |child|
      each_graph_node(child, seen, &block)
    end
  end
  private_class_method :each_graph_node

  # Traverses the graph while carrying inherited headers needed for child exports.
  def each_graph_node_for_export(graph, inherited_headers = [], seen = Set.new, &block)
    return if seen.include?(graph[:class_name])

    seen.add(graph[:class_name])
    headers_for_export = filter_headers_for_class(
      graph[:class_name],
      remove_identifier_fields(Array(graph[:headers]) + Array(inherited_headers))
    )
    block.call(graph, headers_for_export)

    prefixed_parent_headers = prefix_headers_with_class_name(graph[:headers], graph[:class_name])
    child_inherited_headers = remove_identifier_fields(Array(inherited_headers) + Array(prefixed_parent_headers))

    graph[:has_many].each do |child|
      each_graph_node_for_export(child, child_inherited_headers, seen, &block)
    end
  end
  private_class_method :each_graph_node_for_export

  # Prefixes headers with the underscored class name to preserve parent context.
  def prefix_headers_with_class_name(headers, class_name)
    klass = class_name.is_a?(Class) ? class_name : class_name.constantize
    prefix = klass.name.underscore
    Array(headers).map { |header| "#{prefix}_#{header}" }
  end
  private_class_method :prefix_headers_with_class_name

  # Returns the required exportable headers for the given class.
  def mandatory_headers_for(klass)
    if klass.respond_to?(:mandatory_fields)
      mandatory = Array(klass.mandatory_fields).map(&:to_s)
      return remove_identifier_fields(mandatory) unless mandatory.empty?
    end

    if klass.respond_to?(:internal_and_external_fields)
      return remove_identifier_fields(klass.internal_and_external_fields.map(&:to_s))
    end

    return remove_identifier_fields(klass.column_names) if klass.respond_to?(:column_names)

    raise ArgumentError, "No export headers available for #{klass.name}"
  end
  private_class_method :mandatory_headers_for

  # Keeps only headers that can actually be exported for the target class.
  def filter_headers_for_class(class_name, headers)
    klass = normalize_class(class_name)
    exportable_headers = if klass.respond_to?(:internal_and_external_fields)
                           remove_identifier_fields(klass.internal_and_external_fields.map(&:to_s))
                         elsif klass.respond_to?(:column_names)
                           remove_identifier_fields(klass.column_names)
                         else
                           []
                         end

    Array(headers).select { |header| exportable_headers.include?(header) }
  end
  private_class_method :filter_headers_for_class

  # Strips primary and foreign key identifiers from a list of field names.
  def remove_identifier_fields(fields)
    Array(fields).map(&:to_s).uniq.reject { |field| field == 'id' || field.end_with?('_id') }
  end
  private_class_method :remove_identifier_fields

  # Normalizes a class reference so callers can pass either a class or its name.
  def normalize_class(root_class)
    root_class.is_a?(String) ? root_class.constantize : root_class
  end
  private_class_method :normalize_class
end
