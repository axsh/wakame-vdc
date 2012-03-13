DcmgrGUI.prototype.usersPanel = function(){
  // Core.jsのクラス利用の初期設定
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/users/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
  
  // ユーザ一覧の空データ
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "login_id":''
    }]
  }

  //　ユーザ詳細の空データ
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "login_id" : "-",
      "create_at" : "-",
      "last_update_at":''
    }
  }
  
  // ボタン名設定
  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_button');
  var update_button_name = $.i18n.prop('update_button');
  var close_button_name = $.i18n.prop('close_button');

  // ページ制御オブジェクト生成 
  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  // ユーザ一覧オブジェクト生成
  var c_list = new DcmgrGUI.List({
    element_id:'#display_users',
    template_id:'#usersListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  // ユーザ詳細パラメータセット
  c_list.setDetailTemplate({
    template_id:'#usersDetailTemplate',
    detail_path:'/users/show/'
  });

  // 一覧内容更新コールバック    
  c_list.element.bind('dcmgrGUI.contentChange', function(event,params){
    var user = params.data.user;
    c_pagenate.changeTotal(user.owner_total);
    c_list.setData(user.results);
    c_list.singleCheckList(c_list.detail_template);

    //　ユーザ情報編集ダイアログ
    //　ダイアログ上のボタン押下時処理
    var edit_user_buttons = {};
    edit_user_buttons[close_button_name] = function() { $(this).dialog('close'); };
    edit_user_buttons[update_button_name] = function(event) {
	var login_id = $(this).find('#login_id').val();
	var name = $(this).find('#user_name').val();
	var locale = $(this).find('#sellocale_locale').val();
	var time_zone = $(this).find('#seltimezone').val();
        var uuid = $(this).find('#uuid').val();
	var data ='login_id=' + login_id 
                  +'&name='  + name 
                  +'&locale=' + locale
                  +'&time_zone=' + time_zone;
	var request = new DcmgrGUI.Request;
	request.post({
	  "url": '/users/edit_user/' + uuid + '.json',
          "data": data,
          success: function(json,status) {
	   bt_refresh.element.trigger('dcmgrGUI.refresh');
	   c_list.checkRadioButton(uuid);
	  }
        });
 
	$(this).dialog("close");
    }

    // 編集ダイアログ生成（定義）
    var bt_edit_user = new DcmgrGUI.Dialog({
	target:'.edit_user',
	width:600,
	height:240,
	title:$.i18n.prop('edit_user_header'),
	path:'/edit_user',
	button:edit_user_buttons
    });

    // ユーザ一覧中の編集ボタンコールバック
    bt_edit_user.target.bind('click',function(event){
	var uuid = $(this).attr('id').replace(/edit_([a-z0-9]+)/,'$1'); 
	if (uuid) {
		bt_edit_user.open({"ids":[uuid]});
	}
	c_list.checkRadioButton(uuid);
    });
    $(bt_edit_user.target).button({ disabled: false });

    // 選択ユーザからグループへの紐付けダイアログ
    // ダイアログ中のボタン押下時処理
    var link_group_buttons = {};
    link_group_buttons[close_button_name] = function() { $(this).dialog('close'); };
    link_group_buttons[update_button_name] = function(event) {
	var self = this;
        var user_uuid = $(self).find('#user_uuid').val();
	var pr_group_uuid = "";
	$(self).find("[type='radio']").each(function() {
		if($(this).is(':checked')) {
			pr_group_uuid = $(this).val();
		}
	});
	var data = 'pr_group_uuid=' + pr_group_uuid;
	var i = 0;	
	$(self).find('#sel_link').each(function(key,value) {
		if ($(this).is(':checked')) {
			data = data + '&sel_group_uuid['+ i  +']=' + $(this).val();
			i += 1;
		}
	});		
	var request = new DcmgrGUI.Request;
	request.post({
	  "url": '/users/link_user_groups/' + user_uuid + '.json',
          "data": data,
          success: function(json,status) {
	   bt_refresh.element.trigger('dcmgrGUI.refresh');
	   c_list.checkRadioButton(user_uuid);
	  },
	  error: function() {
	 }
        });
 
	$(this).dialog("close");
    }

   // グループへの関連付けダイアログ定義
    var bt_link_group = new DcmgrGUI.Dialog({
	target:'.link_group',
	width:500,
	height:500,
	title:$.i18n.prop('link_group_header'),
	path:'/link_group',
	button:link_group_buttons,
	callback: function(){
		var self = this;
                // 指定のプライマリグループがリンクされていない場合、自動的にリンクする
      		$(this).find("[type='radio']").each(function(key,value) {
			$(value).click(function(){
				if ($(value).is(':checked')) {
					var radio_val = $(value).val();
					var sel_links = $(self).find('#sel_link');
					sel_links.each(function() {
						if($(this).val() == radio_val) {
							$(this).attr('checked',true);
						}
					});
				};
			});
		});
                // プライマリグループをリンク対象から外す場合、自動的にプライマリ指定もはずす
		$(this).find('#sel_link').click(function() {
			if ($(this).is(':checked') != true) {
				//alert('nothing!');
				var sel_value = $(this).val();
				var radios = $(self).find("[type='radio']");
				radios.each(function() {
					if($(this).val() == sel_value) {
						$(this).attr('checked',false);
					}
				});
			};
		});
    	}
    });

   // メイン画面の関連付けボタン押下時の処理（ダイアログ表示）
   bt_link_group.target.bind('click',function(event){
	var uuid = $(this).attr('id').replace(/link_([a-z0-9]+)/,'$1'); 
	if (uuid) {
		bt_link_group.open({"ids":[uuid]});
	}
	c_list.checkRadioButton(uuid);
    });

    $(bt_link_group.target).button({ disabled: false });
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();

  // 更新ボタン処理  
  bt_refresh.element.bind('dcmgrGUI.refresh', function(){
    //Update list element
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/users/list/', c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList', {request:list_request})
    
    $.each(c_list.checked_list, function(check_id,obj){
      //All remove detail element
      $($('#detail').find('#'+check_id)).remove();
      
      //All reload detail element
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/users/show/', check_id)
      },true);
    });
  });
  
  // ページャ更新時処理
  c_pagenate.element.bind('dcmgrGUI.updatePagenate', function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  // ユーザ作成ダイアログボタン押下時処理  
  var create_user_buttons = {};
  create_user_buttons[close_button_name] = function() { 
    $(this).dialog("destroy");
    $(this).remove(); 
  };

  create_user_buttons[create_button_name] = function() { 
    // フォーム全部をバリデーション
    var f = $('#fm');
    var valid = f.validate().form();
    if(valid) { // バリデーション通過時
        var login_id = $(this).find('#login_id').val();
        var password = $(this).find('#pass').val();
        var name = $(this).find('#user_name').val();
        var primary_account_id = $(this).find('#primary_account_id').val();
        var locale = $(this).find('#sellocale_locale').val();
        var time_zone = $(this).find('#seltimezone').val();
        var data ='login_id=' + login_id 
		  +'&password=' + password
                  +'&name='  + name 
                  +'&primary_account_id=' + primary_account_id
                  +'&locale=' + locale
                  +'&time_zone=' + time_zone;
        var request = new DcmgrGUI.Request;
        request.post({
            "url": '/users/create_user',
            "data": data,
            success: function(json,status) {
                // ダイアログを削除
                bt_create_user.content.dialog("destroy");
                bt_create_user.content.remove();
	        bt_refresh.element.trigger('dcmgrGUI.refresh');
            }
        });
     }
  }
  
  // ユーザ作成ダイアログ定義
  var bt_create_user = new DcmgrGUI.Dialog({
    target:'.create_user',
    width:600,
    height:270,
    title:$.i18n.prop('create_user_header'),
    path:'/create_user',
    callback: function(){
        // バリデーション定義
	var f = $('#fm');
	f.validate({
	    errorClass : 'valid-error',
		rules: {
		    'login_id' : {	
			required : true,
              		AN : true,
                        maxlength : 255
		    },
		    'user_name' : {	
             		maxlength : 200
		    },
		    'pass' : {	
			required : true,
             		maxlength : 255
		    }
    		},
    		messages: {
		    'login_id' : {
			required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_login_id')]),
                        AN: $.i18n.prop('validate_errmsg_AN'),
			maxlength: $.validator.format($.i18n.prop('validate_errmsg_maxlength'))
		    },
		    'user_name' : {
			maxlength: $.validator.format($.i18n.prop('validate_errmsg_maxlength'))
		    },
		    'pass' : {
			required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_pass')]),
			maxlength: $.validator.format($.i18n.prop('validate_errmsg_maxlength'))
		    }
    		},
    		onkeyup: false
	});	
    },
    button: create_user_buttons
  });

  // メイン画面上の新規作成ボタン押下時処理  
  bt_create_user.target.bind('click', function(){
    bt_create_user.open();
  });
  
  // ユーザ削除ダイアログ
  // ダイアログ内ボタン押下時処理
  var delete_user_buttons = {};
  delete_user_buttons[close_button_name] = function() { $(this).dialog("close"); };
  delete_user_buttons[delete_button_name] = function() { 
    var user_id = $(this).find('#user_id').val();
    
    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/users/'+ user_id +'.json',
      success: function(json, status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
	$(bt_delete_user.target).button({ disabled: true });
      }
    });
    
    $(this).dialog("close");
  }
  
  // ユーザ削除ダイアログ定義
  var bt_delete_user = new DcmgrGUI.Dialog({
    target: '.delete_user',
    width: 600,
    height: 300,
    title: $.i18n.prop('delete_user_header'),
    path: '/delete_user',
    button: delete_user_buttons
  });
 
  // ラジオボタン選択連動で、ユーザ削除ボタンを活性化 
  dcmgrGUI.notification.subscribe('checked_radio', bt_delete_user, 'enableDialogButton');
  // ページ移動連動で、ユーザ削除ボタンを非活性化
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_user, 'disableDialogButton');
  
  // 各ボタンの初期化
  $(bt_create_user.target).button({ disabled: false });
  $(bt_delete_user.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });

  // メイン画面上の削除ボタンのコールバック  
  bt_delete_user.target.bind('click', function() {
    var id = c_list.currentChecked();
    if( id ){
      bt_delete_user.open({"ids":[id]});
    }
    return false;
  });

  // メイン画面上のデータ取得
  c_list.setData(null);
  c_list.update(list_request,true);
}
