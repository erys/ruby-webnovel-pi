# frozen_string_literal: true

class AddIndexToCharacters < ActiveRecord::Migration[7.0]
  def change
    add_index :characters, :character, unique: true
  end
end
