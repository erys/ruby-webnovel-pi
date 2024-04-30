# frozen_string_literal: true

class AddIndicesToAuthor < ActiveRecord::Migration[7.0]
  def change
    add_index :authors, :jjwxc_id, unique: true
    add_index :authors, :og_name, unique: true
  end
end
