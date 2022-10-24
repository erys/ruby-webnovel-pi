class AddSubtitlesToChapters < ActiveRecord::Migration[7.0]
  def change
    add_column :chapters, :og_subtitle, :string
    add_column :chapters, :tl_subtitle, :string
  end
end
