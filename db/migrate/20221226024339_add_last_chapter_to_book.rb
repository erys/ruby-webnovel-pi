class AddLastChapterToBook < ActiveRecord::Migration[7.0]
  def change
    add_column :books, :last_chapter, :integer
  end
end
