require 'csv'

module ImportFileHelper
  def self.define_attributes(row_hash)
    attributes = {}
    attributes['role_id'] = Role.student.id
    attributes['name'] = row_hash[:username]
    attributes['full_name'] = row_hash[:full_name]
    attributes['email'] = row_hash[:email]
    attributes['password'] = row_hash[:password]
    attributes['email_on_submission'] = 1
    attributes['email_on_review'] = 1
    attributes['email_on_review_of_review'] = 1
    # Handle is set to the users' name by default; when a new user is created
    attributes['handle'] = row_hash[:name]
    attributes
  end

  def self.create_new_user(attributes, session)
    existing_user = User.find_by(name: attributes['name'])

    if existing_user
      # User with the same name already exists, handle accordingly
      # You can update the existing user's attributes here or take other actions
      existing_user.update!(attributes)
      @user = existing_user
    else
      # User with the same name doesn't exist, proceed with creating a new user
      @user = User.new(attributes)
      @user.parent_id = session[:user].id
      @user.save!
    end

    @user

  end
end
