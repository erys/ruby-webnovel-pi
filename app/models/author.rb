# == Schema Information
#
# Table name: authors
#
#  id         :bigint           not null, primary key
#  og_name    :string           not null
#  tl_name    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Author < ApplicationRecord
	has_many :books
end
