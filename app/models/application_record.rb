class ApplicationRecord < ActiveRecord::Base
  include Logging
  primary_abstract_class
end