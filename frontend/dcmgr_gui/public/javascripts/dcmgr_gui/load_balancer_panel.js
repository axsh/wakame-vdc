DcmgrGUI.prototype.loadBalancerPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = {
    "url" : DcmgrGUI.Util.getPagePath('/load_balancers/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };

  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{}]
  }

  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {}
  }

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });

  var c_list = new DcmgrGUI.List({
    element_id:'#display_load_balancers',
    template_id:'#loadBalancersListTemplate',
    maxrow:maxrow,
    page:page
  });

  var close_button_name = $.i18n.prop('close_button');
  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_button');

  c_list.setDetailTemplate({
    template_id:'#loadBalancersDetailTemplate',
    detail_path:'/load_balancers/show/'
  });

  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var load_balancer = params.data.load_balancer;
    c_pagenate.changeTotal(load_balancer.total);
    c_list.setData(load_balancer.results);
    c_list.singleCheckList(c_list.detail_template);
  });

  var bt_refresh  = new DcmgrGUI.Refresh();

  var create_load_balancer_buttons = {};
  create_load_balancer_buttons[close_button_name] = function() { $(this).dialog("close"); };
  create_load_balancer_buttons[create_button_name] = function() {
    var display_name = $(this).find('#display_name').val();
    var load_balancer_protocol = $(this).find('#load_balancer_protocol').val();
    var load_balancer_port = $(this).find('#load_balancer_port').val();
    var instance_protocol = $(this).find('#instance_protocol').val();
    var instance_port = $(this).find('#instance_port').val();
    var certificate_name = $(this).find('#certificate_name').val();
    var public_key = $(this).find('#public_key').val();
    var private_key = $(this).find('#private_key').val();
    var certificate_chain = $(this).find('#certificate_chain').val();
    var cookie_name = $(this).find('#cookie_name').val();

    var data = "display_name="+display_name
               +"&load_balancer_protocol="+load_balancer_protocol
               +"&load_balancer_port="+load_balancer_port
               +"&instance_protocol="+instance_protocol
               +"&instance_port="+instance_port
               +"&certificate_name="+certificate_name
               +"&private_key="+private_key
               +"&public_key="+public_key
               +"&certificate_chain="+certificate_chain
               +"&cookie_name="+cookie_name;

    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/load_balancers',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }

  var bt_create_load_balancer = new DcmgrGUI.Dialog({
    target:'.create_load_balancer',
    width:600,
    height:430,
    title:$.i18n.prop('create_load_balancer_header'),
    path:'/create_load_balancer',
    callback: function(){
      bt_create_load_balancer.disabledButton(1, false);
   },
    button: create_load_balancer_buttons
  });

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/load_balancers/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})

    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      $($('#detail').find('#'+check_id)).remove();
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/load_balancers/show/',check_id)
      },true);
    });
  });

  bt_create_load_balancer.target.bind('click',function(){
    bt_create_load_balancer.open();
  });

  $(bt_create_load_balancer.target).button({ disabled: false });
  $(bt_refresh.target).button({ disabled: false });

  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}
