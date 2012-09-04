DcmgrGUI.prototype.securityGroupPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/security_groups/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
  
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "description":'',
      "display_name":''
    }]
  }
  
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "description" : "-",
      "display_name" : "-",
      "rule":''
    }
  }
  
  var config_tooltip = {
    cluezIndex: 10000,
    width: 450,
    height: 450,
    waitImage: false,
    positionBy: 'auto',
    ajaxCache: false,
    dropShadow: true,
    dropShadowSteps: 6,
    arrows: true,
    cursor: '',
    sticky: true,
    closePosition: 'title',
    closeText: 'Close',
    mouseOutClose: false,
    local: true,
    localIdPrefix: null,
    localIdSuffix: null,
    hideLocal: true
  };
  
  var security_group_button_callback = function(){
    var security_group_help = new DcmgrGUI.ToolTip({
      'target': '#security_group_help',
      'element': this
    });
    
    var params = { 'button': bt_create_security_group, 'element_id': 1 };
    $(this).find('#security_group_display_name').bind('paste', params, DcmgrGUI.Util.availableTextField);
    $(this).find('#security_group_display_name').bind('keyup', params, DcmgrGUI.Util.availableTextField);

    $(this).find('#rule_help').hide();
    security_group_help.create(config_tooltip);
    dcmgrGUI.notification.subscribe('close_dialog', security_group_help, 'close');
  }

  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_button');
  var update_button_name = $.i18n.prop('update_button');
  var close_button_name = $.i18n.prop('close_button');

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_security_groups',
    template_id:'#securityGroupsListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  c_list.setDetailTemplate({
    template_id:'#securityGroupsDetailTemplate',
    detail_path:'/security_groups/show/'
  });
    
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var security_group = params.data.security_group;
    c_pagenate.changeTotal(security_group.total);
    c_list.setData(security_group.results);
    c_list.singleCheckList(c_list.detail_template);

    var edit_security_group_buttons = {};
    edit_security_group_buttons[close_button_name] = function() { $(this).dialog("close"); };
    edit_security_group_buttons[update_button_name] = function(event) {
      var security_group_id = $(this).find('#security_group_id').val();
      var description = $(this).find('#security_group_description').val();
      var display_name = $(this).find('#security_group_display_name').val();
      var rule = $(this).find('#security_group_rule').val();
      var data ='description=' + description
                +'&display_name=' + display_name
                +'&rule=' + rule;

      var request = new DcmgrGUI.Request;
      request.put({
        "url": '/security_groups/'+ security_group_id +'.json',
        "data": data,
        success: function(json,status){
         bt_refresh.element.trigger('dcmgrGUI.refresh');
        }
      });
      
      $(this).dialog("close");
    }
    
    var bt_edit_security_group = new DcmgrGUI.Dialog({
      target:'.edit_security_group',
      width:500,
      height:580,
      title:$.i18n.prop('edit_security_group_header'),
      path:'/edit_security_group',
      button: edit_security_group_buttons,
      callback: function(){
        var security_group_help = new DcmgrGUI.ToolTip({
          'target': '#security_group_help',
          'element': this
        });

        var params = { 'button': bt_edit_security_group, 'element_id': 1 };
        $(this).find('#security_group_display_name').bind('paste', params, DcmgrGUI.Util.availableTextField);
        $(this).find('#security_group_display_name').bind('keyup', params, DcmgrGUI.Util.availableTextField);

        $(this).find('#rule_help').hide();
        security_group_help.create(config_tooltip);
        dcmgrGUI.notification.subscribe('close_dialog', security_group_help, 'close');
      }
    });

    bt_edit_security_group.target.bind('click',function(event){
      var uuid = $(this).attr('id').replace(/edit_(sg-[a-z0-9]+)/,'$1');
      if( uuid ){
        bt_edit_security_group.open({"ids":[uuid]});
      }
      c_list.checkRadioButton(uuid);
    });
    
    $(bt_edit_security_group.target).button({ disabled: false });
    
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    //Update list element
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/security_groups/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})

    var check_id = c_list.currentChecked();
    //remove detail element
    $($('#detail').find('#'+check_id)).remove();
    $(bt_delete_security_group.target).button({ disabled: true });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });
  
  var create_security_group_buttons = {};
  create_security_group_buttons[close_button_name] = function() { $(this).dialog("close"); };
  create_security_group_buttons[create_button_name] = function() { 
    var display_name = $(this).find('#security_group_display_name').val();
    var description = $(this).find('#security_group_description').val();
    var rule = $(this).find('#security_group_rule').val();
    var data = 'display_name=' + display_name
             +'&description=' + description
             +'&rule=' + rule;

    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/security_groups.json',
      "data": data,
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });

    $(this).dialog("close");
  }
  
  var bt_create_security_group = new DcmgrGUI.Dialog({
    target:'.create_security_group',
    width:500,
    height:550,
    title:$.i18n.prop('create_security_group_header'),
    path:'/create_security_group',
    button: create_security_group_buttons,
    callback: security_group_button_callback
  });
  
  bt_create_security_group.target.bind('click',function(){
    bt_create_security_group.open();
    bt_create_security_group.disabledButton(1,true);
  });
  
  var delete_security_group_buttons = {};
  delete_security_group_buttons[close_button_name] = function() { $(this).dialog("close"); };
  delete_security_group_buttons[delete_button_name] = function() { 
    var security_group_id = $(this).find('#security_group_id').val();
    var request = new DcmgrGUI.Request;
    request.del({
      "url": '/security_groups/'+ security_group_id +'.json',
      success: function(json,status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
      }
    });
    
    $(this).dialog("close");
  }
  
  var bt_delete_security_group = new DcmgrGUI.Dialog({
    target:'.delete_security_group',
    width:400,
    height:250,
    title:$.i18n.prop('delete_security_group_header'),
    path:'/delete_security_group',
    button: delete_security_group_buttons
  });
  
  bt_delete_security_group.target.bind('click',function(){
    var id = c_list.currentChecked();
    if( id ){
      bt_delete_security_group.open({"ids":[id]});
    }
    return false;
  });
  
  dcmgrGUI.notification.subscribe('checked_radio', bt_delete_security_group, 'enableDialogButton');
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_security_group, 'disableDialogButton');
  
  $(bt_create_security_group.target).button({ disabled: false });
  $(bt_delete_security_group.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });
  
  c_list.setData(null);
  c_list.update(list_request,true);
}
