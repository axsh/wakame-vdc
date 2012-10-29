DcmgrGUI.prototype.dashboardPanel = function(){

  var bt_refresh  = new DcmgrGUI.Refresh();
  var loading_image = DcmgrGUI.Util.getLoadingImage('ball');
  var notification_title_length = 28;
  var title_set = {};

  bt_refresh.element.bind('dcmgrGUI.refresh', function(){

    $("#total_instance").empty().html(loading_image);
    $("#total_image").empty().html(loading_image);
    $("#total_volume").empty().html(loading_image);
    $("#total_backup").empty().html(loading_image);
    $("#total_network").empty().html(loading_image);
    $("#total_security_group").empty().html(loading_image);
    $("#total_keypair").empty().html(loading_image);
    $("#total_load_balancer").empty().html(loading_image);

    var request = new DcmgrGUI.Request;
    request.get({
      "url": '/accounts/usage.json',
      success: function(json, status){
        var fill_usage = function(id, quota_key) {
          var usage = json[quota_key];
          var usage_msg = usage['current'];
          if( typeof usage['quota'] != 'undefined' ){
            usage_msg = usage_msg + "/" + usage['quota'];
          }
          $(id).html(usage_msg);
        }

        fill_usage('#total_instance', 'instance.count');
        fill_usage('#total_image', 'image.count');
        fill_usage('#total_volume', 'volume.count');
        fill_usage('#total_backup', 'backup_object.count');
        fill_usage('#total_network', 'network.count');
        fill_usage('#total_security_group', 'security_group.count');
        fill_usage('#total_keypair', 'ssh_key_pair.count');
        fill_usage('#total_load_balancer', 'load_balancer.count');
      }
    });
  });

  $('.article').hide();
  $('.notification_title').click(function(){
    var current_id = $(this).attr('for');
    var article_id = '#article-' + current_id;
    var title = title_set[current_id];
    if ($(article_id).is(':hidden')) {
      $(this).html(title);
    } else {
      $(this).html(DcmgrGUI.Util.slice(notification_title_length, title));
    }
    $(article_id).slideToggle();
  });

  $('.notification_title').each(function(){
    var title = $(this).html();
    var current_id = $(this).attr('for');
    title_set[current_id] = title;
    if(title.length >= notification_title_length) {
      $(this).html(DcmgrGUI.Util.slice(notification_title_length, title));
    }
  });

  $(bt_refresh.target).button({ disabled: false });
  bt_refresh.element.trigger('dcmgrGUI.refresh');
}
