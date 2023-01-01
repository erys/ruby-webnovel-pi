# frozen_string_literal: true

# Controller for library wide backups
class BackupController < ApplicationController
  include ZipTricks::RailsStreaming

  # generates database and chapter backup
  def generate
    response.headers['Content-Disposition'] =
      "attachment; filename=webnovel-library-backup-#{Time.now.strftime('%Y-%m-%d_%H_%M_%S')}.zip"
    zip_tricks_stream do |zip|
      zip.write_stored_file('LIBRARY') { |_| }
      Book.all.each do |book|
        book.add_to_zip(zip, dir: book.short_name)
      end
    end
  end

  # loads data from backup into
  def load_backup

  end

  # shows restore view
  def restore

  end
end
