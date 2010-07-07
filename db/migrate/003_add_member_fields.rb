class AddMemberFields < ActiveRecord::Migration
  def self.up
    remove_column :members, :name
    %w(first_name last_name street city state zip lettered home work cell fax email_2 occupation spouse).each do |field|
      add_column :members, field.to_sym, :string
    end
    %w(paid nl_mailed list_serv_removal).each do |field|
      add_column :members, field.to_sym, :boolean
    end
    add_column :members, :notes, :text
    add_column :members, :dob, :date
  end
  
  def self.down
    %w(first_name last_name street city state zip lettered home work cell fax email_2 occupation spouse paid nl_mailed list_serv_removal notes dob).each do |field|
      remove_column :members, field.to_sym
    end
    add_column :members, :name, :string
  end
end
