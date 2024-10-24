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
    ExpertizaLogger.info("Created #{self.class.name}: #{self.attributes}")
  end

  def log_find
    ExpertizaLogger.info("Found #{self.class.name}: #{self.attributes}")
  end

  def log_update
    ExpertizaLogger.info("Updated #{self.class.name}: #{self.attributes}")
  end

  def log_destroy
    ExpertizaLogger.info("Destroyed #{self.class.name}: #{self.attributes}")
  end
end
