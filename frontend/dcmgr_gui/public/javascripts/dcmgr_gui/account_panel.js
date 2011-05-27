DcmgrGUI.prototype.accountPanel = function(){
  var last_login_at = $('#last_login_at').html(); 
  last_login_at = DcmgrGUI.date.parseISO8601(last_login_at);  
  last_login_at = DcmgrGUI.date.setTimezoneOffset(last_login_at, dcmgrGUI.getConfig('time_zone_utc_offset'));
  $('#last_login_at').html(DcmgrGUI.date.getI18n(last_login_at));
}
