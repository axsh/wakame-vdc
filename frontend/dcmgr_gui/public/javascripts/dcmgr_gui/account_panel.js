DcmgrGUI.prototype.accountPanel = function(){
  var last_updated_at = DcmgrGUI.date.parseISO8601($('#last_updated_at').html());  
  $('#last_updated_at').html(DcmgrGUI.date.getI18n(last_updated_at));
}
