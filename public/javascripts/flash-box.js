jQuery.fn.flashBox = function( options ) {
  $(this).hide();
  var opts = $.extend(jQuery.fn.flashBox.defaults, options);
  var flash_raw = $.cookies.get(opts.cookieName);
  if(flash_raw == null) { return this; }
  var flash = $.evalJSON(unescape(flash_raw.replace(/\+/g, ' ')));
  if((txt = flash.notice) != null) {
    $(this).text(txt);
    $(this).show();
    $(this).addClass(opts.noticeClass);
  } else if((txt = flash.error) != null) {
    $(this).text(txt);
    $(this).show();
    $(this).addClass(opts.errorClass);
  }
  $.cookies.del(opts.cookieName, {path: '/'})
  return this;
}
jQuery.fn.flashBox.defaults = { noticeClass : 'flash-notice',
                                errorClass  : 'flash-error',
                                cookieName  : 'flash' };
$(document).ready(function() {
  $('.flash-box').flashBox();
});

