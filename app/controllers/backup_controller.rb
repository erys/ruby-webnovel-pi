# frozen_string_literal: true

# Controller for library wide backups
class BackupController < ApplicationController
  include ZipTricks::RailsStreaming

  # generates database and chapter backup
  def generate
    fresh_when Time.current
    send_file_headers! filename: "webnovel-library-backup-#{Time.now.strftime('%Y-%m-%d_%H_%M_%S')}.zip"
    zip_tricks_stream do |zip|
      book_dirs = []
      Book.find_each do |book|
        book.add_to_zip(zip, dir: book.short_name)
        book_dirs.push(book.short_name)
      end
      zip.write_deflated_file('LIBRARY') { |sink| sink << book_dirs.join("\n") }
    end
  end

  # loads data from backup into
  def load_backup

  end

  # shows restore view
  def restore

  end
end
