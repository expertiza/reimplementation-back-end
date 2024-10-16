module Logging
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_find :log_find
    after_update :log_update
    after_destroy :log_destroy
  end

  private

  def log_create
    Rails.logger.info("Created #{self.class.name}: #{self.attributes}")
  end

  def log_find
    Rails.logger.info("Found #{self.class.name}: #{self.attributes}")
  end

  def log_update
    Rails.logger.info("Updated #{self.class.name}: #{self.attributes}")
  end

  def log_destroy
    Rails.logger.info("Destroyed #{self.class.name}: #{self.attributes}")
  end
end
