DcmgrGUI.prototype.dashboardPanel = function(){
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  var loading_image = DcmgrGUI.Util.getLoadingImage('ball');
  
  bt_refresh.element.bind('dcmgrGUI.refresh', function(){
    
    $("#total_instance").empty().html(loading_image);
    $("#total_image").empty().html(loading_image);
    $("#total_volume").empty().html(loading_image);
    $("#total_snapshot").empty().html(loading_image);
    $("#total_security_group").empty().html(loading_image);
    $("#total_keypair").empty().html(loading_image);
    
    parallel({
      total_instance: $.getJSON('/instances/total.json'),
      total_image: $.getJSON('/images/total.json'),
      total_volume: $.getJSON('/volumes/total.json'),
      total_snapshot: $.getJSON('/snapshots/total.json'),
      total_security_group: $.getJSON('/security_groups/total.json'),
      total_keypair: $.getJSON('/keypairs/total.json')
    }).next(function(results) {
      $('#total_instance').html(results.total_instance);
      $('#total_image').html(results.total_image);
      $('#total_volume').html(results.total_volume);
      $('#total_snapshot').html(results.total_snapshot);
      $('#total_security_group').html(results.total_security_group);
      $('#total_keypair').html(results.total_keypair);
    });
    
  });
 
  bt_refresh.element.trigger('dcmgrGUI.refresh');
}