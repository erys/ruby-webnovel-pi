# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.6.1/dist/jquery.js", preload: true
pin "bootstrap", to: 'bootstrap.min.js', preload: true
pin "@popperjs/core", to: "popper.js", preload: true
pin "clipboard", to: "https://ga.jspm.io/npm:clipboard@2.0.11/dist/clipboard.js", preload: true
