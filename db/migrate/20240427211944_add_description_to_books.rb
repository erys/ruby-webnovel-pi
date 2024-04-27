# frozen_string_literal: true

class AddDescriptionToBooks < ActiveRecord::Migration[7.0]
  def change
    add_column :books, :og_description, :text
  end
end
