
class Node < ApplicationRecord
  has_paper_trail


  belongs_to :parent, class_name: 'Node', foreign_key: 'parent_id', inverse_of: false
  has_many :children, class_name: 'Node', foreign_key: 'parent_id', dependent: :nullify, inverse_of: false

  def self.get(_sortvar = nil, _sortorder = nil, _user_id = nil, _show = nil, _parent_id = nil, _search = nil); end

  def children(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, search = nil); end

  def partial_name
  end

  def self.leaf?
    false
  end

  def name; end

  def directory; end

  def creation_date; end

  def modified_date; end

  def child_type; end
end
