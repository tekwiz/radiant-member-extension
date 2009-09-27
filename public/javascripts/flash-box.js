jQuery.fn.flashBox = function( options ) {
  var opts = $.extend(jQuery.fn.flashBox.defaults, options);
  var flash_raw = $.cookies.get(opts.cookieName);
  if(flash_raw == null) { return this; }
  var flash = $.evalJSON(unescape(flash_raw.replace(/\+/g, ' ')));
  if((txt = flash.notice) != 'undefined') {
    $(this).text(txt);
    $(this).show();
    $(this).addClass(opts.flashNoticeClass);
  } else if((txt = flash.error) != 'undefined') {
    $(this).text(txt);
    $(this).show():
    $(this).addClass(opts.flashErrorClass);
  }
  $.cookies.del(opts.cookieName, {path: '/'})
  return this;
}
jQuery.fn.flashBox.defaults = { noticeClass : 'flash-notice',
                                errorClass  : 'flash-error',
                                cookieName  : 'flash' };
$('.flash-box').flashBox();
