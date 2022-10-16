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
});
