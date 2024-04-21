class AddFieldsToOriginalChapter < ActiveRecord::Migration[7.0]
  def change
    add_column :original_chapters, :title, :string
    add_column :original_chapters, :main_text, :text
    add_column :original_chapters, :footnote, :text
    add_column :original_chapters, :subtitle, :string
    add_column :original_chapters, :substitutions, :string, array: true, default: []
  end
end
