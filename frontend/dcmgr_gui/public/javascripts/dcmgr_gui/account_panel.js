DcmgrGUI.prototype.accountPanel = function(){
  var last_login_at = $('#last_login_at').html(); 
  last_login_at = DcmgrGUI.date.parseISO8601(last_login_at);  
  last_login_at = DcmgrGUI.date.setTimezone(last_login_at, dcmgrGUI.getConfig('time_zone'));
  $('#last_login_at').html(DcmgrGUI.date.getI18n(last_login_at));
}
