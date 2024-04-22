# frozen_string_literal: true

# == Schema Information
#
# Table name: characters
#
#  id                 :bigint           not null, primary key
#  character          :string(1)        not null
#  global_occurrences :integer
#  master_freq        :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Character < ApplicationRecord
  has_many :character_occurrences, dependent: :destroy
end
