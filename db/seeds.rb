# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# character list
character_file = File.read(Rails.root.join("db/data/initial_character_list.dat"))
character_lines = character_file.split("\n")
character_lines.each do |line|
	data = line.split("\t")
	next unless data.length == 2
	Character.create(character: data[0], master_freq: data[1], global_occurrences: 0)
end
