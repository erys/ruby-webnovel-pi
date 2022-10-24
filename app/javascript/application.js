// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import jQuery from 'jquery'
import ClipboardJS from 'clipboard'
import * as bootstrap from "bootstrap"

window.$ = window.jQuery = jQuery;
$(document).on('ready turbo:load', function() {
  var clipboard = new ClipboardJS('.clipboard-btn');
  console.log(clipboard);
//  $('.dropdown-toggle').dropdown()
  console.log("It works on each visit!")

  var buttons = document.querySelectorAll(".toggle-button");

  buttons.forEach(function(button) {
    button.addEventListener("click", function (e) {
      var btn = new bootstrap.Button(e.target);
      console.log("test")
      btn.toggle();
    });
  });
});
