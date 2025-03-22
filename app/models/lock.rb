class Lock < ApplicationRecord
    belongs_to :user, class_name: 'User', foreign_key: 'user_id', inverse_of: false
    
    def self.get_lock()
    end

    def self.release_lock()
    end

    def self.create_lock()
    end

    def self.lock_between?()
    end

end
