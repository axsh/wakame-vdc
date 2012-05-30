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
    c_pagenate.changeTotal(network.owner_total);
    c_list.setData(network.results);
    c_list.multiCheckList(c_list.detail_template);
  });
  
  c_list.filter.add(function(data){
    var results = data.network.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.created_at = DcmgrGUI.date.parseISO8601(results[i].result.created_at);
      results[i].result.created_at = DcmgrGUI.date.setTimezoneOffset(results[i].result.created_at, dcmgrGUI.getConfig('time_zone_utc_offset'));
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

  $(bt_refresh.target).button({ disabled: false });
  
  //list
  c_list.setData(null);
  c_list.update(list_request,true);  
}
