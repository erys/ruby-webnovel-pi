class AddStatusesToBooks < ActiveRecord::Migration[7.0]
  def change
    add_column :books, :translation_status, :string, default: Book::IN_PROGRESS
    add_column :books, :original_status, :string, default: Book::COMPLETED
  end
end
