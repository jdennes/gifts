$(document).ready(function() {
  $("div[id|=title]").click(function() {
    var gifts = $(this).parent().children("div[id|=gifts]");
    var icon = $(this).children(".icon");
    if (gifts.is(":visible")) {
      gifts.slideUp();
      icon.html('<img src="/images/plus.gif" />')
    } else {
      gifts.slideDown();
      icon.html('<img src="/images/minus.gif" />')
    }
  });
});