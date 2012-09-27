DcmgrGUI.prototype.notificationView = function(options){
  var notification_endpoint = options.notification_endpoint;
  var request = new DcmgrGUI.Request;
  request.get({
    "url": '/notifications.json?limit=5&sort=desc',
    success: function(json, status){
      var data = json.results;
      $('#notifications').html($('#notificationsTemplate').tmpl(data));
    }
  });
}
