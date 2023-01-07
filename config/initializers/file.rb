class File
  def self.nice_join(*dirs)
    dirs = dirs.compact_blank.reject { |dir| dir == '.' }
    self.join(*dirs)
  end
end
