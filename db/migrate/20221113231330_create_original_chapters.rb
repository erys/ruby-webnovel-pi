class CreateOriginalChapters < ActiveRecord::Migration[7.0]
  def change
    create_table :original_chapters do |t|
      t.integer :ch_number, null: false
      t.references :book, null: false, foreign_key: true
      t.string :link
      t.string :font_name

      t.timestamps
    end
  end
end
