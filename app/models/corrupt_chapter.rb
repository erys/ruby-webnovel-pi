class CorruptChapter
	include ActiveModel::API
	include ActiveModel::Serializers::JSON

	COMPOSE_CHAR = "\u200c"
	CHAPTER_END_STR = "插入书签"
	JJWXC_TEXT = "@无限好文，尽在晋江文学城"

	ATTR_SYMBOLS = [
		:og_text,
		:book_id,
		:ch_number,
		:corrupt_chars,
		:possible_replacements,
		:possible_chars,
		:corrupt_chars_json,
		:parsed,
		:id,
		:subtitle,
	].freeze

	JSON_SYMBOLS = [
		:og_text,
		:book_id,
		:ch_number,
		:corrupt_chars_json,
		:possible_replacements,
		:possible_chars,
		:parsed,
		:id,
		:subtitle,
	].freeze

	attr_accessor *ATTR_SYMBOLS

	def initialize(attributes = nil)
		super
		@id = SecureRandom.uuid
	end

	def persisted?
		ready_for_parse?
	end

	def percent
		((char_to_replace.first_occurrence * 100.0) / og_text.length).round
	end

	def attributes
		JSON_SYMBOLS.map do |symbol|
			[symbol.to_s, nil]
		end.to_h
	end
	def ready_for_parse?
		og_text.present? && book_id.present?
	end

	def parse
		return if @parsed
		raise 'og_text and book_id must be defined for parsing' unless ready_for_parse?
		book = Book.includes(character_occurrences: :character).find(book_id)
		og_text.gsub!(JJWXC_TEXT, '')
		ch_start = og_text.index("\n") || 0
		ch_end = og_text.index(CHAPTER_END_STR) || og_text.length
		index = ch_start
		corrupt_hash = {}
		book_occurrences = book.character_occurrences.sort.reverse!
		@possible_chars = book_occurrences.map do |occurrence|
			[occurrence.character.character, [occurrence.id, 0]]
		end.to_h
		while index < ch_end
			char = og_text[index]
			if char == COMPOSE_CHAR
				char = og_text[index - 1, 2]
				corrupt_char = corrupt_hash[char]
				if corrupt_char
					corrupt_char.add_occurrence
				else
					corrupt_hash[char] = CorruptCharacter.new({og_bytes: char, first_occurrence: index})
				end
			elsif possible_chars.key?(char)
				possible_chars[char][1] += 1
			end
			index +=1
		end
		@corrupt_chars = corrupt_hash.values.sort.reverse!
		@possible_replacements = possible_chars.select {|_,value| value[1] == 0}.keys
		@parsed = true
	end

	def replace(new_char)
		replaced_char = char_to_replace
		replaced_char.correct_char = new_char
		@possible_replacements.delete(new_char)
		puts char_to_replace
	end

	def can_undo?
		@corrupt_chars.first&.known?
	end

	def prev_char
		return nil unless can_undo?
		return @corrupt_chars.last if char_to_replace.nil?
		index = @corrupt_chars.index(char_to_replace)
		@corrupt_chars[index - 1]
	end

	def undo
		previous = prev_char
		return unless previous.present?
		@possible_replacements.push(previous.correct_char)
		@possible_replacements = @possible_chars.keys.intersection(@possible_replacements)
		bad_rep = previous.correct_char
		previous.correct_char = nil
		bad_rep
	end

	# for form purposes
	def replacement
		nil
	end
	def char_to_replace
		@corrupt_chars.find { |char| !char.known? }
	end

	def next_bytes
		index = @corrupt_chars.index(char_to_replace)
		if index < corrupt_chars.length - 1
			@corrupt_chars[index + 1].og_bytes
		else
			nil
		end
	end

	def prev_bytes
		prev_char&.og_bytes
	end

	def done?
		@corrupt_chars.all? { |char| char.known? }
	end

	def unused_chars
		possible_replacements
	end

	def init_chapter
		corrupt_chars.each do |char|
			char.replace(og_text)
			possible_chars[char.correct_char][1] = char.occurrences
		end
		register_occurrences
		chapter = Chapter.new(book_id: book_id, ch_number: ch_number)
		chapter.og_text_data = og_text
		chapter.og_title = og_text.lines.first.strip.force_encoding('utf-8')
		chapter.og_subtitle = subtitle if subtitle.present?
		chapter
	end

	def register_occurrences
		id_hash = possible_chars.values.to_h
		book = Book.includes(:character_occurrences).find(book_id)
		book.character_occurrences.each do |occurrence|
			next if id_hash[occurrence.id] == 0
			occurrence.increment!(:occurrences, id_hash[occurrence.id])
			# this field is only used the first time you clean a chapter for a book
			# so removing for performance reasons
			# occurrence.character.global_occurrences += id_hash[occurrence.id]
			# occurrence.character.save
		end
	end

	def to_json
		@corrupt_chars_json = @corrupt_chars&.map { |char| char.serializable_hash }
		super
	end

	class CorruptCharacter
		include Comparable
		include ActiveModel::API
		include ActiveModel::Serializers::JSON
		CHAR_ATTR = [
			:og_bytes,
			:occurrences,
			:correct_char,
			:first_occurrence,
		].freeze
		attr_accessor *CHAR_ATTR

		def initialize(attributes = nil)
			super
			@occurrences ||= 1
		end

		def replace(og_text)
			og_text.gsub!(og_bytes, correct_char)
		end

		def attributes
			CHAR_ATTR.map { |symbol| [symbol.to_s, nil] }.to_h
		end

		def known?
			@correct_char.present?
		end

		def add_occurrence
			@occurrences += 1
		end

		def highlight(excerpt, cur_char)
			if known?
				excerpt.gsub!(og_bytes, "<span class=\"text-info\">#{@correct_char}</span>")
			elsif self == cur_char
				excerpt.gsub!(og_bytes, '<strong class="text-danger">XXX</strong>')
			else
				excerpt.gsub!(og_bytes, '<em class="text-secondary">xxx</em>')
			end
		end

		def <=>(other)
			[occurrences, -self.first_occurrence] <=> [other.occurrences, -other.first_occurrence]
		end
	end

	class << self
		def from_json(json_string)
			chap = new.from_json(json_string)
			chap.corrupt_chars = chap.corrupt_chars_json&.map { |hash| CorruptCharacter.new(hash) }
			chap
		end
	end
end
