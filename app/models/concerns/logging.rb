# Logging concern to automatically log model CRUD operations to the database. 
# It can be enabled for a given model by using "include Logging". 
# It will then automatically log all CRUD operations for the model. 
# This concern was created to log all of the CRUD operations being 
# executed against the database by logging them as ExpertizaLogs with 
# the info log level. Enabling this for all models would create 
# too many logs to effectively parse and provide meaning; however, 
# for certain models that are not frequently used, it can provide 
# key insights into the behavior of the application. 

module Logging
  extend ActiveSupport::Concern

  # Set up hooks to call logging when CRUD operations are performed. 
  included do
    after_create :log_create
    after_find :log_find
    after_update :log_update
    after_destroy :log_destroy
  end

  private

  # Logs the creation of an object to the database. With the 
  # hooks created above, this will automatically log the class name 
  # and its attributes after it has been successfully created. 
  # This may provide excellent insight when desiring to audit the 
  # object data being created for certain classes. 
  def log_create
    ExpertizaLogger.info("Created #{self.class.name}: #{self.attributes}")
  end

  # Logs the retrieval of an object from the database. With the 
  # hooks created above, this will automatically log the class name 
  # and its attributes after it has been successfully found. 
  # This may provide useful insights when attempting to see the data 
  # retrieved before it can ever be modified or when wanting to audit 
  # if certain critical objects are ever accessed when it should otherwise 
  # be impossible. 
  def log_find
    ExpertizaLogger.info("Found #{self.class.name}: #{self.attributes}")
  end

  # Logs the update of an object to the database. Similar to 
  # the log_create method above, this may be useful when attempting to 
  # validate that new data is being updated and persisted to the database. 
  # Similar to log_find, it may be useful to audit the modification of key 
  # classes such as a gradebook to ensure that grades are only modified as 
  # intended. 
  def log_update
    ExpertizaLogger.info("Updated #{self.class.name}: #{self.attributes}")
  end

  # Logs the deletion of an object from the database. With the 
  # hooks from above, this will automatically log the class name 
  # and the object's attributes after it has been successfully deleted
  # from the database. This may be useful for certain critical data 
  # that should never be deleted, enabling it and its deletion to be 
  # recorded, effectively providing a last instance of the data and 
  # allowing it to potentially reveal why it was deleted through what it 
  # contained. 
  def log_destroy
    ExpertizaLogger.info("Destroyed #{self.class.name}: #{self.attributes}")
  end
end
