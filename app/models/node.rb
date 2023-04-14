
class Node < ApplicationRecord
  has_paper_trail


  belongs_to :parent, class_name: 'Node', foreign_key: 'parent_id', inverse_of: false
  has_many :children, class_name: 'Node', foreign_key: 'parent_id', dependent: :nullify, inverse_of: false

  def self.get(_sortvar = nil, _sortorder = nil, _user_id = nil, _show = nil, _parent_id = nil, _search = nil); end

  def get_children(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, search = nil); end

  def get_partial_name
  end


  def is_leaf
    false
  end


  def self.table; end

  def get_name; end

  def get_directory; end

  def get_creation_date; end

  def get_modified_date; end

  def get_child_type; end
end