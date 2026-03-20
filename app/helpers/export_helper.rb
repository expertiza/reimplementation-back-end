# frozen_string_literal: true

require 'set'

module ExportHelper
  module_function

  # Builds a recursive graph of a class and related associations.
  # The graph uses a single has_many list and can include inferred inverse
  # has_many edges from belongs_to declarations in other models.
  # Also runs Export.perform for each unique class in that graph.
  def export_has_many_graph(root_class)
    graph = build_has_many_graph(root_class)
    headers_by_class = {}

    each_graph_node(graph) do |node|
      klass = node[:class_name].constantize
      headers = mandatory_headers_for(klass)

      # Ensure child exports include mandatory fields used to link child back to parent.
      if node[:parent_external_relation]
        headers |= node[:parent_external_relation][:fields]
      end

      headers_by_class[node[:class_name]] ||= []
      headers_by_class[node[:class_name]] |= headers
      headers_by_class[node[:class_name]] = remove_identifier_fields(headers_by_class[node[:class_name]])
    end

    exports = {}
    headers_by_class.each do |class_name, headers|
      exports[class_name] = Export.perform(class_name.constantize, headers)
    end

    { graph: graph, exports: exports }
  end

  def build_has_many_graph(root_class, visited = Set.new, parent_class: nil)
    klass = normalize_class(root_class)
    class_name = klass.name

    relation_to_parent = external_relation_to_parent(klass, parent_class)

    if visited.include?(class_name)
      return {
        class_name: class_name,
        parent_external_relation: relation_to_parent,
        cyclic_reference: true,
        has_many: []
      }
    end

    visited.add(class_name)

    explicit_has_many_edges = has_many_edges_for(klass, visited)
    inferred_from_belongs_to_edges = inferred_inverse_has_many_edges_for(klass, visited)

    {
      class_name: class_name,
      parent_external_relation: relation_to_parent,
      has_many: dedupe_edges(explicit_has_many_edges + inferred_from_belongs_to_edges)
    }
  end

  def has_many_edges_for(klass, visited)
    klass.reflect_on_all_associations(:has_many).filter_map do |association|
      begin
        associated_klass = association.klass
      rescue StandardError
        next
      end

      {
        association: association.name.to_s,
        association_type: 'has_many',
        graph: build_has_many_graph(associated_klass, visited, parent_class: klass)
      }
    end
  end
  private_class_method :has_many_edges_for

  # Treat belongs_to as the inverse of has_many:
  # if ModelX belongs_to klass, include ModelX as a child node of klass.
  def inferred_inverse_has_many_edges_for(klass, visited)
    descendants = ActiveRecord::Base.descendants.select { |model| model < ApplicationRecord }

    descendants.filter_map do |candidate|
      next if candidate == klass

      association = candidate.reflect_on_all_associations(:belongs_to).find do |belongs_to_association|
        begin
          belongs_to_association.klass == klass || klass <= belongs_to_association.klass
        rescue StandardError
          false
        end
      end

      next unless association

      {
        association: candidate.name.underscore.pluralize,
        association_type: 'inferred_has_many_from_belongs_to',
        inferred_from: association.name.to_s,
        graph: build_has_many_graph(candidate, visited, parent_class: klass)
      }
    end
  end
  private_class_method :inferred_inverse_has_many_edges_for

  def dedupe_edges(edges)
    edges.uniq { |edge| [edge[:association], edge[:graph][:class_name]] }
  end
  private_class_method :dedupe_edges

  def each_graph_node(graph, seen = Set.new, &block)
    signature = [graph[:class_name], graph[:parent_external_relation]&.dig(:ref_class)]
    return if seen.include?(signature)

    seen.add(signature)
    block.call(graph)

    graph[:has_many].each do |child|
      each_graph_node(child[:graph], seen, &block)
    end
  end
  private_class_method :each_graph_node

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

  def external_relation_to_parent(klass, parent_class)
    return nil unless parent_class && klass.respond_to?(:external_classes)

    ext = klass.external_classes&.find do |external_class|
      next false unless external_class.respond_to?(:ref_class)

      external_class.ref_class == parent_class || parent_class <= external_class.ref_class
    end

    return nil unless ext

    {
      ref_class: ext.ref_class.name,
      should_look_up: ext.should_look_up,
      should_create: ext.should_create,
      look_up_field: ext.instance_variable_get(:@look_up_field)&.to_s,
      fields: external_mandatory_fields(ext)
    }
  end
  private_class_method :external_relation_to_parent

  def external_mandatory_fields(external_class)
    ref_class = external_class.ref_class
    return [] unless ref_class.respond_to?(:mandatory_fields)

    mandatory = Array(ref_class.mandatory_fields).map(&:to_s)
    namespaced = mandatory.map { |field| ExternalClass.append_class_name(ref_class, field) }
    remove_identifier_fields(namespaced)
  end
  private_class_method :external_mandatory_fields

  def remove_identifier_fields(fields)
    Array(fields).map(&:to_s).uniq.reject { |field| field == 'id' || field.end_with?('_id') }
  end
  private_class_method :remove_identifier_fields

  def normalize_class(root_class)
    root_class.is_a?(String) ? root_class.constantize : root_class
  end
  private_class_method :normalize_class
end
