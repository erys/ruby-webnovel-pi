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
  console.log("It works on each visit!")

  var buttons = document.querySelectorAll(".toggle-button");

  buttons.forEach(function(button) {
    button.addEventListener("click", function (e) {
      $(this).toggleClass('active')
    });
  });

  $(".paste-btn").click(paste_text);
});

// TODO: #15 make this work with Ctrl-Z, if it's possible
async function paste_text(event) {
  $($(event.currentTarget).attr('paste-target')).val(await navigator.clipboard.readText());
}
