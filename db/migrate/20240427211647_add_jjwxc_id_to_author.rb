# frozen_string_literal: true

class AddJjwxcIdToAuthor < ActiveRecord::Migration[7.0]
  def change
    add_column :authors, :jjwxc_id, :integer
  end
end
