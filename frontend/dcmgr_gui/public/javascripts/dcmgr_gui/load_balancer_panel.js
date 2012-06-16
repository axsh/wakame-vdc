DcmgrGUI.prototype.loadBalancerPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = {
    "url" : DcmgrGUI.Util.getPagePath('/load_balancers/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };

  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "uuid":'',
      "size":'',
      "backup_object_id":'',
      "created_at":'',
      "state":''
    }]
  }

  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "uuid" : "-",
      "size" : "-",
      "backup_object_id" : "-",
      "created_at" : "-",
      "updated_at" : "-",
      "state" : ""
    }
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
    c_list.multiCheckList(c_list.detail_template);
    c_list.element.find(".edit_load_balancer").each(function(key,value){
      $(this).button({ disabled: false });
      var uuid = $(value).attr('id').replace(/edit_(vol-[a-z0-9]+)/,'$1');
      if( uuid ){
        $(this).bind('click',function(){
          bt_edit_load_balancer.open({"ids":[uuid]});
        });
      } else {
        $(this).button({ disabled: true });
      }
    });
  });

  var bt_refresh  = new DcmgrGUI.Refresh();

  var create_load_balancer_buttons = {};
  create_load_balancer_buttons[close_button_name] = function() { $(this).dialog("close"); };
  create_load_balancer_buttons[create_button_name] = function() {
    var display_name = $(this).find('#display_name').val();
    var load_balancer_size = $(this).find('#load_balancer_size').val();
    var unit = $(this).find('#unit').find('option:selected').val();
    if(!load_balancer_size){
     $('#load_balancer_size').focus();
     return false;
    }
    var data = "size="+load_balancer_size+"&unit="+unit+"&display_name="+display_name;

    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/load_balancers',
      "data": data,
      success: function(json,status){
        console.log(json);
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    $(this).dialog("close");
  }

  var bt_create_load_balancer = new DcmgrGUI.Dialog({
    target:'.create_load_balancer',
    width:400,
    height:200,
    title:$.i18n.prop('create_load_balancer_header'),
    path:'/create_load_balancer',
    callback: function(){
      var self = this;
      var loading_image = DcmgrGUI.Util.getLoadingImage('boxes');
      $(this).find('#select_load_balancer').empty().html(loading_image);

      var request = new DcmgrGUI.Request;
      var is_ready = {
        'display_name': false,
        'load_balancer_size': false
      }

      var ready = function(data) {
        if(data['display_name'] == true &&
           data['load_balancer_size'] == true) {
          bt_create_load_balancer.disabledButton(1, false);
        } else {
          bt_create_load_balancer.disabledButton(1, true);
        }
      }

      $(this).find('#display_name').keyup(function(){
       if( $(this).val() ) {
         is_ready['display_name'] = true;
         ready(is_ready);
       } else {
         is_ready['display_name'] = false;
         ready(is_ready);
       }
      });

      $(this).find('#load_balancer_size').keyup(function(){
       if( $(this).val() ) {
         is_ready['load_balancer_size'] = true;
         ready(is_ready);
       } else {
         is_ready['load_balancer_size'] = false;
         ready(is_ready);
       }
      });

      request.get({
        "url": '/load_balancers/show_load_balancers.json',
        success: function(json,status){
          console.log(json);
          var select_html = '<select id="load_balancer" name="load_balancer"></select>';
          $(self).find('#select_load_balancer').empty().html(select_html);
          var results = json.load_balancer.results;
          var size = results.length;
          var select_load_balancer = $(self).find('#load_balancer');
          for (var i=0; i < size ; i++) {
            var uuid = results[i].result.uuid;
            var html = '<option value="'+ uuid +'">'+uuid+'</option>';
            select_load_balancer.append(html);
          }

          var params = { 'button': bt_create_load_balancer, 'element_id': 1 };
        }
      });
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

  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}
