$(document).ready(function() {
  $("div[id|=title]").click(function() {
    var gifts = $(this).parent().children("div[id|=gifts]");
    if (gifts.is(":visible")) {
      gifts.slideUp();
    } else {
      gifts.slideDown();
    }
  });
});