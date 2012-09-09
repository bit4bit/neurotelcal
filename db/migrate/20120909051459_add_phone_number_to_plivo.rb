class AddPhoneNumberToPlivo < ActiveRecord::Migration
  def change
    add_column :plivos, :phonenumber, :string, :default => "0000000000"
  end
end
