# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins %r{\Ahttps://.*\.jjwxc\.net\z}
    resource 'api/original_chapter', headers: :any, methods: %i[get post]
    resource 'corrupt_chapter', headers: :any, methods: %i[cur_bytes cur_chapter_id]
  end
end
