DcmgrGUI.prototype.networkPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/networks/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
    
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "uuid":'',
      "created_at":'',
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "uuid" : "-",
      "created_at" : "-",
      "updated_at" : "-",
    }
  }

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_networks',
    template_id:'#networksListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  c_list.setDetailTemplate({
    template_id:'#networksDetailTemplate',
    detail_path:'/networks/show/'
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var network = params.data.network;
    c_pagenate.changeTotal(network.total);
    c_list.setData(network.results);
    c_list.multiCheckList(c_list.detail_template);
  });
  
  c_list.filter.add(function(data){
    var results = data.network.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.created_at = DcmgrGUI.date.parseISO8601(results[i].result.created_at);
      results[i].result.created_at = DcmgrGUI.date.setTimezone(results[i].result.created_at, dcmgrGUI.getConfig('time_zone'));
      results[i].result.created_at = DcmgrGUI.date.getI18n(results[i].result.created_at);
    }
    return data;
  });

  var bt_refresh  = new DcmgrGUI.Refresh();
  
  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/networks/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      $($('#detail').find('#'+check_id)).remove();
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/networks/show/',check_id)
      },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  //
  // Launch instance:
  //

  var close_button_name = $.i18n.prop('close_button'); 
  var create_button_name = $.i18n.prop('create_button');

  var create_network_buttons = {};
  create_network_buttons[close_button_name] = function() { $(this).dialog("close"); };  
  create_network_buttons[create_button_name] = function() {
    var display_name = $(this).find('#display_name').val();
    var description = $(this).find('#description').val();
    var ipv4_network = $(this).find('#ipv4_network').val();
    var ipv4_gw = $(this).find('#ipv4_gw').val();
    var prefix = $(this).find('#prefix').val();
    var network_mode = $(this).find('#network_mode').val();

    var data = "&display_name="+display_name
          +"&description="+description
          +"&ipv4_network="+ipv4_network
          +"&ipv4_gw="+ipv4_gw
          +"&prefix="+prefix
          +"&network_mode="+network_mode;
    
    request = new DcmgrGUI.Request;
    request.post({
      "url": '/networks',
      "data": data,
      success: function(json,status){
       bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_create_network = new DcmgrGUI.Dialog({
    target:'.create_network',
    width:583,
    height:600,
    title:$.i18n.prop('create_network_header'),
    path:'/create_network',
    callback: function(){
      var self = this;

      bt_create_network.disabledButton(1, false);
    },
    button: create_network_buttons
  });

  bt_create_network.target.bind('click',function(){
    bt_create_network.open();
    bt_create_network.disabledButton(1, true);
  });

  $(bt_create_network.target).button({ disabled: false });
  $(bt_refresh.target).button({ disabled: false });

 //list
  c_list.setData(null);
  c_list.update(list_request,true);  
}
