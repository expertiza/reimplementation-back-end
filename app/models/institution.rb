class Institution < ApplicationRecord
  validates :name, presence: true, uniqueness: true, allow_blank: false, length: { maximum: 50 }
  has_many :users, dependent: :restrict_with_error
  
  def exists?
    true
  end
end





