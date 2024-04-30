# frozen_string_literal: true

# == Schema Information
#
# Table name: authors
#
#  id         :bigint           not null, primary key
#  og_name    :string           not null
#  tl_name    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  jjwxc_id   :integer
#
# Indexes
#
#  index_authors_on_jjwxc_id  (jjwxc_id) UNIQUE
#  index_authors_on_og_name   (og_name) UNIQUE
#
class Author < ApplicationRecord
  has_many :books, dependent: :restrict_with_exception

  def display_name
    tl_name.presence || og_name
  end

  def second_name
    return nil if tl_name.blank? || tl_name == og_name

    og_name
  end

  def full_display
    second_name ? "#{display_name} (#{second_name}}" : display_name
  end

  def jjwxc_link
    "https://www.jjwxc.net/oneauthor.php?authorid=#{jjwxc_id}" if jjwxc_id.present?
  end

  def book_count
    books.length
  end

  def self.maybe_create_author(og_name:, **author_params)
    if author_params.present?
      create_with(**author_params).find_or_create_by(og_name:)
    else
      find_or_create_by(og_name:)
    end
  end
end
