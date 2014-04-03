$('#next-button').click(function() {
  var aimValue = $('#aim-select option:selected').text();
  if (aimValue != '') {
    $('#second-tab').click();
  }
});
