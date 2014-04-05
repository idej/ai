$('#next-button').click(function() {
  var aimValue = $('#aim-select option:selected').text();
  if (aimValue != '') {
    var strId = '.' + aimValue.replace(/\s/g, '-');
    $(strId).remove();
    $('#first-tab').removeAttr("data-toggle");
    $('#second-tab').attr("data-toggle", "tab");
    $('#second-tab').click();
  }
});

$('#search-button').click(function(event) {
  if ($('#second-step select option:selected').text() == '')  {
    return false;
  }
});

$('#back-button').click(function() {
    $('#second-tab').removeAttr("data-toggle");
    $('#first-tab').attr("data-toggle", "tab");
    $('#first-tab').click();
});
