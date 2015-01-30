require_relative '20141119184643_devise_create_users'

class CleanupDevise < ActiveRecord::Migration
  def change
    revert DeviseCreateUsers
    create_table(:users)
  end
end
