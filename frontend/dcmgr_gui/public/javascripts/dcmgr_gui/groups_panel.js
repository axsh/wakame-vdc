DcmgrGUI.prototype.groupsPanel = function(){
  // Core.jsのクラス利用の初期設定
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/groups/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
  
  // グループ一覧の空データ
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "name":''
    }]
  }

  // グループ詳細の空データ
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "name" : "-",
      "created_at" : "-",
      "updated_at":''
    }
  }
  
　// ボタン名設定
  var create_button_name = $.i18n.prop('create_button');
  var delete_button_name = $.i18n.prop('delete_button');
  var update_button_name = $.i18n.prop('update_button');
  var close_button_name = $.i18n.prop('close_button');
 
  // ページ制御オブジェクトを生成
  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  // グループ一覧オブジェクト生成
  var c_list = new DcmgrGUI.List({
    element_id:'#display_groups',
    template_id:'#groupsListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  // グループ詳細パラメータセット
  c_list.setDetailTemplate({
    template_id:'#groupsDetailTemplate',
    detail_path:'/groups/show/'
  });
  
  // 一覧内容更新コールバック  
  c_list.element.bind('dcmgrGUI.contentChange', function(event,params){
    var account = params.data.account;
    c_pagenate.changeTotal(account.total);
    c_list.setData(account.results);
    c_list.singleCheckList(c_list.detail_template);

    // グループ情報編集ダイアログ
    var edit_group_buttons = {};
    // 編集ダイアログ内の閉じるボタンコールバック
    edit_group_buttons[close_button_name] = function() { $(this).dialog('close'); };
    // ダイアログ内の更新ボタンコールバック
    edit_group_buttons[update_button_name] = function(event) {
	var name = $(this).find('#group_name').val();
	var description = $(this).find('#description').val();
        var uuid = $(this).find('#uuid').val();
	var data ='name=' + name 
                  +'&description='  + description; 
	var request = new DcmgrGUI.Request;
	request.post({
	  "url": '/groups/edit_group/' + uuid + '.json',
          "data": data,
          success: function(json,status) {
	   bt_refresh.element.trigger('dcmgrGUI.refresh');
	  }
        });
 
	$(this).dialog("close");
    }

    // 編集ダイアログ生成（定義）
    var bt_edit_group = new DcmgrGUI.Dialog({
	target:'.edit_group',
	width:600,
	height:300,
	title:$.i18n.prop('edit_group_header'),
	path:'/edit_group',
	button:edit_group_buttons
    });

    // グループ一覧中の編集ボタンコールバック
    bt_edit_group.target.bind('click',function(event){
	var uuid = $(this).attr('id').replace(/edit_([a-z0-9]+)/,'$1'); 
	if (uuid) {
		//* データセンタアカウントでなければ、編集ダイアログを起動
		if (uuid != '00000000') {
			bt_edit_group.open({"ids":[uuid]});
		}
		else
		{
			alert($.i18n.prop('errmsg_for_edit_admin'));
		}
	}
	c_list.checkRadioButton(uuid);
    });
    $(bt_edit_group.target).button({ disabled: false });

    // 選択グループからユーザへの紐付け（一覧選択）
    var link_user_buttons = {};
    // ダイアログ内の閉じるボタンコールバック
    link_user_buttons[close_button_name] = function() { $(this).dialog('close'); };
　　// ダイアログ内の更新ボタンコールバック
    link_user_buttons[update_button_name] = function(event) {
	var self = this;
        // グループのuuidを取得
        var group_uuid = $(self).find('#group_uuid').val();
	var data = ''
	var i = 0;
        // 一覧選択されたユーザuuidを配列形式の引数に紐付け	
	$(self).find('#sel_link').each(function(key,value) {
		if ($(this).is(':checked')) {
			data = data + '&sel_user_uuid['+ i  +']=' + $(this).val();
			i += 1;
		}
	});		
        // 通信リクエストオブジェクト生成
	var request = new DcmgrGUI.Request;
        // リクエストをPOST
	request.post({
	  "url": '/groups/link_group_users/' + group_uuid + '.json',
          "data": data,
          success: function(json,status) {
	   bt_refresh.element.trigger('dcmgrGUI.refresh');
	   c_list.checkRadioButton(group_uuid);
	  }
        });
 
	$(this).dialog("close");
    }

    // ユーザへの関連付けダイアログ定義
    var bt_link_user = new DcmgrGUI.Dialog({
	target:'.link_user',
	width:500,
	height:500,
	title:$.i18n.prop('link_user_header'),
	path:'/link_user',
	button:link_user_buttons
    });

   // メイン画面の関連付けボタン押下時の処理（ダイアログ表示）
   bt_link_user.target.bind('click',function(event){
	var uuid = $(this).attr('id').replace(/link_([a-z0-9]+)/,'$1'); 
	if (uuid) {
		bt_link_user.open({"ids":[uuid]});
	}
	c_list.checkRadioButton(uuid);
    });

    $(bt_link_user.target).button({ disabled: false });
  });
  var bt_refresh  = new DcmgrGUI.Refresh();
  
　// 更新ボタン処理
  bt_refresh.element.bind('dcmgrGUI.refresh', function(){
    //Update list element
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/groups/list/', c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList', {request:list_request})
    
    $.each(c_list.checked_list, function(check_id,obj){
      //All remove detail element
      $($('#detail').find('#'+check_id)).remove();
      
      //All reload detail element
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/groups/show/', check_id)
      },true);
    });
  });

  // ページャ更新時処理
  c_pagenate.element.bind('dcmgrGUI.updatePagenate', function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });

  // グループ作成ダイアログ
  var create_group_buttons = {};
  // ダイアログ内の閉じるボタンコールバック
  create_group_buttons[close_button_name] = function() { 
    $(this).dialog("destroy");
    $(this).remove(); 
  };

  // ダイアログ内の作成ボタンコールバック
  create_group_buttons[create_button_name] = function() {
    // フォーム全部をバリデーション
    var f = $('#fm');
    var valid = f.validate().form();
    if(valid) { // バリデーション通過時
        // ダイアログ内のIDから設定値を取得
	var name = $(this).find('#group_name').val();
	var description = $(this).find('#description').val();
	var enable = $(this).find('#enable').val();
        // 送信パラメータを作成
	var data ='name=' + name 
                  +'&description='  + description 
                  +'&enable=' + enable;
        var request = new DcmgrGUI.Request;
        // リクエスト送信
        request.post({
            "url": '/groups/create_group',
            "data": data,
            // 成功時のコールバック
            success: function(json,status) {
                // ダイアログを削除
                bt_create_group.content.dialog("destroy");
                bt_create_group.content.remove();
	        bt_refresh.element.trigger('dcmgrGUI.refresh');
            }
        });
    }
  }
  
  // グループ作成ダイアログ定義
  var bt_create_group = new DcmgrGUI.Dialog({
    target:'.create_group',
    width:600,
    height:300,
    title:$.i18n.prop('create_group_header'),
    path:'/create_group',
    callback: function(){
        // バリデーション定義
	var f = $('#fm');
	f.validate({
	    errorClass : 'valid-error',
		rules: {
		    'group_name' : {	
			required : true,
              		AN : true,
                        maxlength : 255
		    },
		    'description' : {	
             		maxlength : 255
		    }
    		},
    		messages: {
		    'group_name' : {
			required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_group_name')]),
                        AN: $.i18n.prop('validate_errmsg_AN'),
			maxlength: $.validator.format($.i18n.prop('validate_errmsg_maxlength'))
		    },
		    'description' : {
			maxlength: '<BR>' + $.i18n.prop('validate_errmsg_maxlength')
		    }
    		},
    		onkeyup: false
	});	
    },
    button: create_group_buttons
  });
  
  // メイン画面上の新規作成ボタン押下時のコールバック.
  bt_create_group.target.bind('click', function(){
    bt_create_group.open();
  });
  
  // グループ削除ダイアログ
  var delete_group_buttons = {};
  // ダイアログ内の閉じるボタンコールバック
  delete_group_buttons[close_button_name] = function() { $(this).dialog("close"); };
  // ダイアログ内の削除ボタンコールバック
  delete_group_buttons[delete_button_name] = function() { 
    var group_id = $(this).find('#group_id').val();
    var request = new DcmgrGUI.Request;
    request.post({
      "url": '/groups/'+ group_id +'.json',
      success: function(json, status){
        bt_refresh.element.trigger('dcmgrGUI.refresh');
  	$(bt_delete_group.target).button({ disabled: true });
      }
    });
    
    $(this).dialog("close");
  }
 
　// グループ削除ダイアログ定義 
  var bt_delete_group = new DcmgrGUI.Dialog({
    target: '.delete_group',
    width: 600,
    height: 300,
    title: $.i18n.prop('delete_group_header'),
    path: '/delete_group',
    button: delete_group_buttons
  });
  
  // ラジオボタンチェックイベント連動で、グループ削除ボタンを活性化
  dcmgrGUI.notification.subscribe('checked_radio', bt_delete_group, 'enableDialogButton');
  // ページ制御のページ移動連動で、グループ削除ボタンを非活性化
  dcmgrGUI.notification.subscribe('change_pagenate', bt_delete_group, 'disableDialogButton');

  // 各ボタンの初期化
  $(bt_create_group.target).button({ disabled: false });
  $(bt_delete_group.target).button({ disabled: true });
  $(bt_refresh.target).button({ disabled: false });

  // メイン画面上の削除ボタンのコールバック
  bt_delete_group.target.bind('click', function() {
    var id = c_list.currentChecked();
    if( id ){
	// データセンタアカウントでなければ、削除ダイアログを起動
	if (id != '00000000') {
	      bt_delete_group.open({"ids":[id]});
	}
	else
	{
  		alert($.i18n.prop('errmsg_for_delete_admin'));
	}
    }
    return false;
  });

  // メイン画面ロード時のデータ取得
  c_list.setData(null);
  c_list.update(list_request,true);
}

