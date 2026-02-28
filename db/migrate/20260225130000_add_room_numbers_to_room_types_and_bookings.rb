class AddRoomNumbersToRoomTypesAndBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :room_types, :room_numbers_text, :text unless column_exists?(:room_types, :room_numbers_text)
    add_column :bookings, :assigned_room_numbers_text, :text unless column_exists?(:bookings, :assigned_room_numbers_text)
  end
end
