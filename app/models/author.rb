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
class Author < ApplicationRecord
  has_many :books, dependent: :destroy

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
end
