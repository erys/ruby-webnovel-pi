# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins %r{\Ahttps://.*\.jjwxc\.net\z}
    resource '/api/*', headers: :any, methods: %i[get post]
  end
end
