DcmgrGUI.prototype.resourceManagePanel = function(){
  // ボタン名
  var create_button_name = $.i18n.prop('create_button');
  var close_button_name = $.i18n.prop('close_button');
  var update_button_name = $.i18n.prop('update_button');
  var delete_button_name = $.i18n.prop('delete_button');

  // ---------------------------------ホストノード作成ダイアログ------------------------------------
  // ダイアログ内の閉じるボタン押下
  var create_resource_hn_buttons = {};
  create_resource_hn_buttons[close_button_name] = function() {
	$(this).dialog("destroy");
        $(this).remove(); 
  }

  // ダイアログ内の作成ボタン押下
  create_resource_hn_buttons[create_button_name] = function() {
    // フォーム全部をバリデーション
    var f = $('#fm');
    var valid = f.validate().form();
    if(valid) {
        // 値を取り込んで、リクエスト送信
    	var account_id = $(this).find('#selaccount_account').val();
    	var cpu_cores = $(this).find('#cpu_cores').val();
    	var memory_size = $(this).find('#memory_size').val();
    	var arch = $(this).find('#arch').val();
    	var hypervisor = $(this).find('#hypervisor').val();
    	var hostid = $(this).find('#hostid').val();
    	var name = $(this).find('#name').val();
    	var data ='account_id=' + account_id 
		  +'&cpu_cores=' + cpu_cores
                  +'&memory_size='  + memory_size 
                  +'&arch=' + arch
                  +'&hypervisor=' + hypervisor
                  +'&hostid=' + hostid
                  +'&name=' + name;
    	var request = new DcmgrGUI.Request;
        // 送信中はマスキング
        $("#create_hostnode_dialog").mask($.i18n.prop('waiting_communicate'));
    	request.post({
        	"url": '/dialog/create_hn_exec',
        	"data": data,
        	success: function(json,status) {
                    // メッセージボックスにて結果表示
                    if (json.result.exitcode == 0) {
                        Sexy.messageBox('info',$.i18n.prop(json.result.message,[json.result.detail]));
                    	bt_create_resource_hn.content.dialog("destroy");
                        bt_create_resource_hn.content.remove();
                    } else {
                        Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                                 "<p>exit code =" + json.result.exitcode  + "</p>" +
                                 "<p>" + json.result.detail + "</p>");
                    }
        	},
                complete: function(xhr,status) {
                        $("#create_hostnode_dialog").unmask();
                }
    	});
    }
  }
  
  // ホストノード作成ダイアログ定義
  var bt_create_resource_hn = new DcmgrGUI.Dialog({
    target:'.create_resource_hostnode',
    width:600,
    height:325,
    title:$.i18n.prop('create_resource_hn_header'),
    path:'/create_hn',
    callback: function(){
        // バリデーション定義
	var f = $('#fm');
	f.validate({
    		errorClass : 'valid-error',
    		rules: {
			'hostid' : {	
				required : true,
                        	AN : true,
                                maxlength : 8
			},
			'cpu_cores' : {	
				required : true,
                        	digits : true,
              			min : 1
			},
			'memory_size' : {	
				required : true,
                        	digits : true,
              			min : 1
			}
    		},
    		messages: {
			'hostid' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_hostid')]),
                        	AN: $.i18n.prop('validate_errmsg_AN'),
				maxlength: $.validator.format($.i18n.prop('validate_errmsg_maxlength'))
			},
			'cpu_cores' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_cpu_cores')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			},
			'memory_size' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_memory_size')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			}
    		},
    		onkeyup: false	
  　    });
    },
    button: create_resource_hn_buttons
  });

  // メイン画面で作成ボタン押下時、ダイアログ表示
  bt_create_resource_hn.target.bind('click', function(){
    bt_create_resource_hn.open();
  });

  // ---------------------------------ホストノード編集＆削除ダイアログ------------------------------------
  // ダイアログ内の閉じるボタン押下
  var edit_and_delete_resource_hn_buttons = {};
  edit_and_delete_resource_hn_buttons[close_button_name] = function() { 
  	$(this).dialog("destroy");
        $(this).remove(); 
  };

  // ダイアログ内の削除ボタン押下
  edit_and_delete_resource_hn_buttons[delete_button_name] = function() { 
　  // 値を取り込んでリクエスト送信 
    var hostid = $(this).find('#hostid').val();
    var request = new DcmgrGUI.Request;
    // 送信中はマスキング
    $("#edit_and_delete_hostnode_dialog").mask($.i18n.prop('waiting_communicate'));
    request.post({
      "url": '/dialog/delete_hn_exec/' + hostid,
      success: function(json, status){
         // メッセージボックス表示にて結果表示
         if (json.result.exitcode == 0) {
            Sexy.messageBox('info',$.i18n.prop(json.result.message));
            bt_edit_and_delete_resource_hn.content.dialog("destroy");
            bt_edit_and_delete_resource_hn.content.remove();

         } else {
            Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                            "<p>exit code =" + json.result.exitcode  + "</p>" +
                            "<p>" + json.result.detail + "</p>");
         }
      },
      complete: function(xhr,status) {
          $("#edit_and_delete_hostnode_dialog").unmask();
      }
    });
  }

  // ダイアログ内の更新ボタン押下
  edit_and_delete_resource_hn_buttons[update_button_name] = function() {
    // フォーム全部をバリデーション
    var f = $('#fm');
    var valid = f.validate().form();
    if(valid) {
        // 値を取り込んで、リクエスト送信
    	var account_id = $(this).find('#selaccount_account').val();
    	var cpu_cores = $(this).find('#cpu_cores').val();
    	var memory_size = $(this).find('#memory_size').val();
       	var id = $(this).find('#hostid').val();
    	var name = $(this).find('#name').val();
    	var data ='uuid=' + id 
                  +'&account_id=' + account_id 
		  +'&cpu_cores=' + cpu_cores
                  +'&memory_size='  + memory_size 
                  +'&name=' + name;
    	var request = new DcmgrGUI.Request;
        // 送信中はマスキング
        $("#edit_and_delete_hostnode_dialog").mask($.i18n.prop('waiting_communicate'));
   	request.post({
        	"url": '/dialog/edit_hn_exec',
        	"data": data,
        	success: function(json,status) {
                    // メッセージボックスにて結果表示
                    if (json.result.exitcode == 0) {
                        Sexy.messageBox('info',$.i18n.prop(json.result.message));
                    	bt_edit_and_delete_resource_hn.content.dialog("destroy");
                        bt_edit_and_delete_resource_hn.content.remove();

                    } else {
                        Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                                 "<p>exit code =" + json.result.exitcode  + "</p>" +
                                 "<p>" + json.result.detail + "</p>");
                    }
        	},
                complete: function(xhr,status) {
                        $("#edit_and_delete_hostnode_dialog").unmask();
                }
    	});
    }
  }
  
  // ホストノード編集＆削除ダイアログ定義
  var bt_edit_and_delete_resource_hn = new DcmgrGUI.Dialog({
    target: '.edit_and_delete_resource_hostnode',
    width: 590,
    height: 380,
    title: $.i18n.prop('edit_and_delete_resource_hn_header'),
    path: '/edit_and_delete_hn',
    button: edit_and_delete_resource_hn_buttons,
    callback: function(){      
	var f = $('#fm');
	f.validate({
                // バリデーション定義
    		errorClass : 'valid-error',
    		rules: {
			'cpu_cores' : {	
				required : true,
                        	digits : true,
              			min : 1
			},
			'memory_size' : {	
				required : true,
                        	digits : true,
              			min : 1
			}
    		},
    		messages: {
			'cpu_cores' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_cpu_cores')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			},
			'memory_size' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_memory_size')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			}
    		},
    		onkeyup: false	
  　    });
        // グループ選択時、全ホストノード情報をajaxで取得
        $('#selaccount_account').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var account_id = $('#selaccount_account').val();
    		var request = new DcmgrGUI.Request;
                var data = 'account_id=' + account_id;
    		request.post({
        		"url": '/dialog/get_hn_list',
        		"data": data,
        		success: function(json,status) {
                             // 一覧情報をセーブ、ホストノードIDの一覧セレクトを作成
			     var sel = $('#hostid');
                             $.data(acc,'host_nodes',json.host_node);
                             sel.children().remove();
                             if (json.host_node.total > 0) {
                                for(var i = 0;i < json.host_node.total;i++)
                                {
                                    var rec = json.host_node.results[i].result;
                                    var html = '<option value="' + rec.uuid + '">' + rec.id +'</option>';
                                    sel.append(html);  
                                }
                                // ホストノード選択イベント処理を呼出
                                $('#hostid').change();
                             } 
                             else
                             {
                                // ホストノードがない場合、選択不可にして、画面項目内容クリア
                                var html = '<option value="">' + f.find('#hostnode_nothing').val()  + '</option>';
                                sel.append(html);
                                f.find('#cpu_cores').val("");
                                f.find(':text').attr("disabled","disabled");
                                f.find('#memory_size').val("");
                                f.find('#name').val("");
                                $('#arch').html("<BR>");
                                $('#hypervisor').html("<BR>");
                                $('#status').html("<BR>");
  				bt_edit_and_delete_resource_hn.disabledButton(1,true);
  				bt_edit_and_delete_resource_hn.disabledButton(2,true);
                             }
	                }
    		});
        });
        // ホストノード選択時、ダイアログ内の項目表示内容を更新
        $('#hostid').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var hostid = $('#hostid').val();
                if (hostid != '') {
                        // 一覧情報をキャッシュから取り出し
			var host_node = $.data(acc,'host_nodes');
                        for (var i = 0;i < host_node.total;i++)
                        {
			    var rec = host_node.results[i].result;
                            if (hostid == rec.uuid) {
                            // 選択されたホストノードであれば、項目に値をセット
                                f.find('#cpu_cores').val(rec.offering_cpu_cores);
                                f.find(':text').removeAttr("disabled");
                                f.find('#memory_size').val(rec.offering_memory_size);
                                f.find('#name').val(rec.name);
                                $('#arch').html(f.find('#' + rec.arch).val());
                                $('#hypervisor').html(f.find('#' + rec.hypervisor).val());
                                $('#status').html(rec.status);
                                if (rec.status == "online") {
  				    bt_edit_and_delete_resource_hn.disabledButton(1,true);
　　　　　　　　　　　　　　　　　　 } else {
  				    bt_edit_and_delete_resource_hn.disabledButton(1,false);
                                }
  				bt_edit_and_delete_resource_hn.disabledButton(2,false);
                            }
                        }
                }      
        });
        
        // 初期表示内容で、アカウント選択イベント処理を呼出
        $('#selaccount_account').change();
    }
  });

  // メイン画面のボタン活性化
  $(bt_create_resource_hn.target).button({ disabled: false });
  $(bt_edit_and_delete_resource_hn.target).button({ disabled: false });
 
  // メイン画面で編集／削除ボタン押下時、ダイアログ表示
  bt_edit_and_delete_resource_hn.target.bind('click', function() {
    bt_edit_and_delete_resource_hn.open();
  });

  // ---------------------------------ストレージノード作成ダイアログ------------------------------------
  // ダイアログ内の閉じるボタン押下
  var create_resource_sn_buttons = {};
  create_resource_sn_buttons[close_button_name] = function() {
	$(this).dialog("destroy");
        $(this).remove(); 
  }
 
  // ダイアログ内の作成ボタン押下
  create_resource_sn_buttons[create_button_name] = function() {
    // フォーム全部をバリデーション
    var f = $('#fm');
    var valid = f.validate().form();
    if(valid) {
        // 値を取り込んでリクエスト送信
    	var account_id = $(this).find('#selaccount_account').val();
    	var disk_space = $(this).find('#disk_space').val();
    	var ipaddr = $(this).find('#ipaddr').val();
    	var transport_type = $(this).find('#transport_type').val();
    	var storage_type = $(this).find('#storage_type').val();
    	var storageid = $(this).find('#storageid').val();
    	var base_path = $(this).find('#base_path').val();
    	var snapshot_base_path = $(this).find('#snapshot_base_path').val();
    	var data ='account_id=' + account_id 
		  +'&disk_space=' + disk_space
                  +'&ipaddr='  + ipaddr 
                  +'&transport_type=' + transport_type
                  +'&storage_type=' + storage_type
                  +'&storageid=' + storageid
                  +'&snapshot_base_path=' + snapshot_base_path
                  +'&base_path=' + base_path;
    	var request = new DcmgrGUI.Request;
        // 送信中はマスキング
        $("#create_storagenode_dialog").mask($.i18n.prop('waiting_communicate'));
    	request.post({
        	"url": '/dialog/create_sn_exec',
        	"data": data,
        	success: function(json,status) {
                    // メッセージボックスにて結果表示
                    if (json.result.exitcode == 0) {
                        Sexy.messageBox('info',$.i18n.prop(json.result.message,[json.result.detail]));
			(create_resource_sn_buttons[close_button_name])();
                    	bt_create_resource_sn.content.dialog("destroy");
                        bt_create_resource_sn.content.remove();
                    } else {
                        Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                                 "<p>exit code =" + json.result.exitcode  + "</p>" +
                                 "<p>" + json.result.detail + "</p>");
                    }
        	},
                complete: function(xhr,status) {
                        $("#create_storagenode_dialog").unmask();
                }
    	});
    }
  }

  // ストレージノード作成ダイアログ定義  
  var bt_create_resource_sn = new DcmgrGUI.Dialog({
    target:'.create_resource_storagenode',
    width:583,
    height:600,
    title:$.i18n.prop('create_resource_sn_header'),
    path:'/create_sn',
    callback: function(){
        // バリデーション定義
	var f = $('#fm');
	f.validate({
    		errorClass : 'valid-error',
    		rules: {
			'storageid' : {	
				required : true,
                        	AN : true,
                                maxlength : 8
			},
			'disk_space' : {	
				required : true,
                        	digits : true,
              			min : 1
			},
			'ipaddr' : {	
				required : true,
                        	IP : true
			},
			'base_path' : {	
				required : true,
                        	PATH : true,
              			maxlength : 255
			},
			'snapshot_base_path' : {	
				required : true,
                        	PATH : true,
              			maxlength : 255
			}
    		},
    		messages: {
			'storageid' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_storageid')]),
                        	AN: $.i18n.prop('validate_errmsg_AN'),
				maxlength: $.validator.format($.i18n.prop('validate_errmsg_maxlength'))
			},
			'disk_space' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_disk_space')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			},
			'ipaddr' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_ipaddr')]),
                        	IP: $.i18n.prop('validate_errmsg_IP')
			},
			'base_path' : {
				required: '<BR>' + $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_base_path')]),
                        	PATH: '<BR>' + $.i18n.prop('validate_errmsg_PATH'),
				maxlength: '<BR>' + $.i18n.prop('validate_errmsg_maxlength')
			},
			'snapshot_base_path' : {
				required: '<BR>' + $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_snapshot_base_path')]),
                        	PATH: '<BR>' + $.i18n.prop('validate_errmsg_PATH'),
				maxlength: '<BR>' + $.i18n.prop('validate_errmsg_maxlength')
			}
    		},
    		onkeyup: false	
  　    });
    },
    button: create_resource_sn_buttons
  });
  
  // メイン画面で作成ボタン押下時、ダイアログ表示
  bt_create_resource_sn.target.bind('click', function(){
    bt_create_resource_sn.open();
  });
  
  // ---------------------------------ストレージノード削除ダイアログ------------------------------------
  // ダイアログ内の閉じるボタン押下
  var delete_resource_sn_buttons = {};
  delete_resource_sn_buttons[close_button_name] = function() { 
  	$(this).dialog("destroy");
        $(this).remove(); 
  };

  // 削除ボタン押下処理
  delete_resource_sn_buttons[delete_button_name] = function() {
    // 値を取り込んでリクエスト送信 
    var storageid = $(this).find('#storageid').val();
    var request = new DcmgrGUI.Request;
    // 送信中はマスキング
    $("#delete_storagenode_dialog").mask($.i18n.prop('waiting_communicate'));
    request.post({
      "url": '/dialog/delete_sn_exec/' + storageid,
      success: function(json, status){
         // メッセージボックスにて結果表示
         if (json.result.exitcode == 0) {
            Sexy.messageBox('info',$.i18n.prop(json.result.message));
            bt_delete_resource_sn.content.dialog("destroy");
            bt_delete_resource_sn.content.remove();
         } else {
            Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                            "<p>exit code =" + json.result.exitcode  + "</p>" +
                            "<p>" + json.result.detail + "</p>");
         }
      },
      complete: function(xhr,status) {
         $("#delete_storagenode_dialog").unmask();
      }
     });
  }

  // ストレージノード削除ダイアログ定義
  var bt_delete_resource_sn = new DcmgrGUI.Dialog({
    target: '.delete_resource_storagenode',
    width: 600,
    height: 410,
    title: $.i18n.prop('delete_resource_sn_header'),
    path: '/delete_sn',
    button: delete_resource_sn_buttons,
    callback: function(){
        // アカウント選択時、全ストレージノード情報をajaxで取得      
        $('#selaccount_account').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var account_id = $('#selaccount_account').val();
    		var request = new DcmgrGUI.Request;
                var data = 'account_id=' + account_id;
    		request.post({
        		"url": '/dialog/get_sn_list',
        		"data": data,
        		success: function(json,status) {
                             // 一覧情報をセーブ、ストレージノードIDの一覧セレクトを作成
			     var sel = $('#storageid');
                             $.data(acc,'storage_nodes',json.storage_node);
                             sel.children().remove();
                             if (json.storage_node.total > 0) {
                                for(var i = 0;i < json.storage_node.total;i++)
                                {
                                    var rec = json.storage_node.results[i].result;
                                    var html = '<option value="' + rec.uuid + '">' + rec.id + '</option>';
                                    sel.append(html);  
                                }
                                // ストレージノード選択イベント処理呼出
                                $('#storageid').change();
                             } 
                             else
                             {
                                // ストレージノードがない場合は表示クリア
                                var html = '<option value="">' + f.find('#storagenode_nothing').val()  + '</option>';
                                sel.append(html);
                                $('#disk_space').html("<BR>");
                                $('#ipaddr').html("<BR>");
                                $('#transport_type').html("<BR>");
                                $('#storage_type').html("<BR>");
                                $('#base_path').html("<BR>");
                                $('#snapshot_base_path').html("<BR>");
                                $('#status').html("<BR>");
  				bt_delete_resource_sn.disabledButton(1,true);
                             }
	                }
    		});
        });
        // ストレージノード選択時、ダイアログ内の項目表示内容を更新
        $('#storageid').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var storageid = $('#storageid').val();
                if (storageid != '') {
			var storage_node = $.data(acc,'storage_nodes');
                        for (var i = 0;i < storage_node.total;i++)
                        {
			    var rec = storage_node.results[i].result;
                            if (storageid == rec.uuid) {
                                $('#disk_space').html(rec.offering_disk_space);
                                $('#ipaddr').html(rec.ipaddr);
                                $('#transport_type').html(f.find('#' + rec.transport_type).val());
                                $('#storage_type').html(f.find('#' + rec.storage_type).val());
                                $('#base_path').html(rec.export_path);
                                $('#snapshot_base_path').html(rec.snapshot_base_path);
                                $('#status').html(rec.status);
                                if (rec.status == "online") {
  				    bt_delete_resource_sn.disabledButton(1,true);
　　　　　　　　　　　　　　　　　　 } else {
  				    bt_delete_resource_sn.disabledButton(1,false);
                                }
                            }
                        }
                }      
        });
        
        $('#selaccount_account').change();
    }
  });

  $(bt_create_resource_sn.target).button({ disabled: false });
  $(bt_delete_resource_sn.target).button({ disabled: false });

  
  bt_delete_resource_sn.target.bind('click', function() {
    bt_delete_resource_sn.open();
  });


  // ---------------------------------インスタンススペック作成ダイアログ------------------------------------
  // ダイアログ内の閉じるボタン押下
   var create_resource_is_buttons = {};
  create_resource_is_buttons[close_button_name] = function() {
	$(this).dialog("destroy");
        $(this).remove(); 
  }
  
  // ダイアログ内の作成ボタン押下
  create_resource_is_buttons[create_button_name] = function() {
    // フォーム全部をバリデーション 
    var f = $('#fm');
    var valid = f.validate().form();
    if(valid) {
        // 値を取り込んで、リクエスト送信
    	var account_id = $(this).find('#selaccount_account').val();
    	var cpu_cores = $(this).find('#cpu_cores').val();
    	var memory_size = $(this).find('#memory_size').val();
    	var arch = $(this).find('#arch').val();
    	var hypervisor = $(this).find('#hypervisor').val();
    	var specid = $(this).find('#specid').val();
    	var quota_weight = $(this).find('#quota_weight').val();
    	var data ='account_id=' + account_id 
		  +'&cpu_cores=' + cpu_cores
                  +'&memory_size='  + memory_size 
                  +'&arch=' + arch
                  +'&hypervisor=' + hypervisor
                  +'&specid=' + specid;
        if (quota_weight != "") {
            data = data +'&quota_weight=' + quota_weight;
        }
    	var request = new DcmgrGUI.Request;
        // 送信中はマスキング
        $("#create_spec_dialog").mask($.i18n.prop('waiting_communicate'));
    	request.post({
        	"url": '/dialog/create_is_exec',
        	"data": data,
        	success: function(json,status) {
                    // メッセージボックスにて結果表示
                    if (json.result.exitcode == 0) {
                        Sexy.messageBox('info',$.i18n.prop(json.result.message));
                    	bt_create_resource_is.content.dialog("destroy");
                        bt_create_resource_is.content.remove();
                    } else {
                        Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                                 "<p>exit code =" + json.result.exitcode  + "</p>" +
                                 "<p>" + json.result.detail + "</p>");
                    }
        	},
                complete: function(xhr,status) {
                        $("#create_spec_dialog").unmask();
                }
    	});
    }
  }
  
  // インスタンススペック作成ダイアログ定義
  var bt_create_resource_is = new DcmgrGUI.Dialog({
    target:'.create_spec',
    width:600,
    height:330,
    title:$.i18n.prop('create_resource_is_header'),
    path:'/create_is',
    callback: function(){
        // バリデーション定義
	var f = $('#fm');
	f.validate({
    		errorClass : 'valid-error',
    		rules: {
			'specid' : {	
				required : true,
                        	AN : true,
                                maxlength : 8
			},
			'cpu_cores' : {	
				required : true,
                        	digits : true,
              			min : 1
			},
			'memory_size' : {	
				required : true,
                        	digits : true,
              			min : 1,
                        },
			'quota_weight' : {	
                        	number : true,
                                GT : 0
			}
    		},
    		messages: {
			'specid' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_specid')]),
                        	AN: $.i18n.prop('validate_errmsg_AN'),
				maxlength: $.validator.format($.i18n.prop('validate_errmsg_maxlength'))
			},
			'cpu_cores' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_cpu_cores')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			},
			'memory_size' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_memory_size')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			},
			'quota_weight' : {
                        	number: $.i18n.prop('validate_errmsg_number'),
				GT: $.validator.format($.i18n.prop('validate_errmsg_plus_number'))
			}
    		},
    		onkeyup: false	
  　    });
    },
    button: create_resource_is_buttons
  });
  
  // メイン画面上の作成ボタン押下処理
  bt_create_resource_is.target.bind('click', function(){
    bt_create_resource_is.open();    
  });

  // ---------------------------------追加ドライブ・IF管理ダイアログ------------------------------------
  // ダイアログ内の閉じるボタン押下
  var additional_drives_and_IFs_buttons = {};
  additional_drives_and_IFs_buttons[close_button_name] = function() { 
  	$(this).dialog("destroy");
        $(this).remove(); 
  };

  // ホストノード作成ダイアログ定義
  var bt_additional_drives_and_IFs = new DcmgrGUI.Dialog({
    target: '.additional_drives_and_IFs',
    width: 650,
    height: 650,
    title: $.i18n.prop('additional_drives_and_IFs_header'),
    path: '/additional_drives_and_IFs',
    button: additional_drives_and_IFs_buttons,
    callback: function(){
        var is_accid = '';
        var is_uuid = '';
        // jqGridの定義（追加ドライブ）
	jQuery("#list").jqGrid({
                // データ取得関数(json)
		datatype: function(postdata) {
    		    var request = new DcmgrGUI.Request;
                    var data = 'account_id=' + is_accid +'&uuid=' + is_uuid;
                    for (var key in postdata) {
                        data = data + '&' + key + "=" + postdata[key];
                    }
    		    request.get({
        		"url": '/dialog/get_is_drives_list',
        		"data": data,
        		success: function(json,status) {
				var mygrid = jQuery("#list")[0];
                                jQuery("#list").clearGridData(true);
				mygrid.addJSONData(json);
                        }
                    }); 
                 },
                // 背景ゼブラ描画（効果微妙）
                altRows: true,
                // 列名
		colNames:[$.i18n.prop('item_drive_id'), 
                          $.i18n.prop('item_drive_type'),
                          $.i18n.prop('item_drive_size'),
                          $.i18n.prop('item_index')],
                // 列属性（名前、配置、バリデーション等）
		colModel:[
			{name:'id',align:'center',editable:true,editrules:{required:true},sortable:false},
			{name:'type',align:'center',width:100,sortable:false,editable:true,edittype:"select",
                         editoptions:{value:{local:$.i18n.prop('item_local'),volume:$.i18n.prop('item_volume')}}},
			{name:'drive_size',align:'center',width:100,sortable:false,
                         editable:true,editrules:{integer:true,minValue:1}},
			{name:'index',align:'center',width:100,sortable:false,
                         editable:true,editrules:{integer:true,minValue:0}}
		],
                // 行数
                rowNum:5,
                // 高さ
                height:'115px',
                // 関連するページャ（ページャに操作ボタン有）
                pager:'#pager1',
                // 更新時URL
                editurl: "/dialog/is_drive_change",
                // 表題
		caption: $.i18n.prop('additional_drives_and_IFs_drives_table_title'),
                // 返却されるjsonの形式定義
                jsonReader : {
      		    root:"drive_data",
      	            page: "currpage",
                    total: "totalpages",
                    records: "totalrecords",
                    repeatitems: false,
                    id: "0"
                }
	}).navGrid(
             '#pager1',
              // ページャ上のボタンの有効、無効
              {edit:true,add:true,del:true,search:false,refresh:false},
              // 更新のイベント処理
              {
                 // サブミット前処理（対象のスペックuuidの取り込み）
                 onclickSubmit: function(params,postdata) {
              	   var adddata = {uuid: is_uuid };
		  return adddata;
                 },
                 // 更新後、フォームを閉じる
                 closeAfterEdit: true,
                 // フォーム表示前処理（id,typeは変更不可にする）
                 beforeShowForm: function(formid) {
                   $('#id',formid).attr("disabled","disabled");
                   $('#type',formid).attr("disabled","disabled");
                 }
              },
              // 作成のイベント処理
              {
                 // サブミット前処理（対象のスペックuuidの取り込み）
                 onclickSubmit: function(params,postdata) {
              	   var adddata = {uuid: is_uuid };
		   return adddata;
                 },
                 // 更新後、フォームを閉じる
                 closeAfterAdd: true,
                 // フォーム表示前処理（id,typeは変更可能にする）
                 beforeShowForm: function(formid) {
                   $('#id',formid).removeAttr("disabled");
                   $('#type',formid).removeAttr("disabled");
                 }
              },
              // 削除のイベント処理
              // サブミット前処理（対象のスペックuuidの取り込み）
              {onclickSubmit: function(params,postdata) {
              	var adddata = {uuid: is_uuid };
		return adddata;
              }}
        );
        // jqGridの定義(VIF）定義内容は追加ドライブと同じ
	jQuery("#list2").jqGrid({
		datatype: function(postdata) {
    		    var request = new DcmgrGUI.Request;
                    var data = 'account_id=' + is_accid +'&uuid=' + is_uuid;
                    for (var key in postdata) {
                        data = data + '&' + key + "=" + postdata[key];
                    }
    		    request.get({
        		"url": '/dialog/get_is_vifs_list',
        		"data": data,
        		success: function(json,status) {
				var mygrid = jQuery("#list2")[0];
                                jQuery("#list2").clearGridData(true);
				mygrid.addJSONData(json);
                        }
                    }); 
                },
                altRows: true,
		colNames:[$.i18n.prop('item_IF_id'), 
                          $.i18n.prop('item_bandwidth'),
                          $.i18n.prop('item_index')],
		colModel:[
			{name:'id',align:'center',editable:true,editrules:{required:true},sortable:false},
			{name:'bandwidth',align:'center',width:150,editable:true,sortable:false,
                         editrules:{integer:true,minValue:1}},
			{name:'index',align:'center',width:100,editable:true,sortable:false,
                         editrules:{integer:true,minValue:0}}
		],
                rowNum:5,
                height:'115px',
                pager: '#pager2',
                editurl: "/dialog/is_vif_change",
		caption: $.i18n.prop('additional_drives_and_IFs_IFs_table_title'),
                jsonReader : {
      		    root:"vif_data",
      	            page: "currpage",
                    total: "totalpages",
                    records: "totalrecords",
                    repeatitems: false,
                    id: "0"
                }
	}).navGrid(
             '#pager2',
             {edit:true,add:true,del:true,search:false,refresh:false},
              {
                 onclickSubmit: function(params,postdata) {
              	   var adddata = {uuid: is_uuid };
		  return adddata;
                 },
                 closeAfterEdit: true,
                 beforeShowForm: function(formid) {
                   $('#id',formid).attr("disabled","disabled");
                 }
              },
              {
                 onclickSubmit: function(params,postdata) {
              	   var adddata = {uuid: is_uuid };
		   return adddata;
                 },
                 closeAfterAdd: true,
                 beforeShowForm: function(formid) {
                   $('#id',formid).removeAttr("disabled");
                 }
              },
              {onclickSubmit: function(params,postdata) {
              	var adddata = {uuid: is_uuid };
		return adddata;
              }}
        );
        // グループ選択時、全スペック一覧情報をajaxで取得　
        $('#selaccount_account').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var account_id = $('#selaccount_account').val();
                is_accid = account_id;
    		var request = new DcmgrGUI.Request;
                var data = 'account_id=' + account_id;
    		request.post({
        		"url": '/dialog/get_is_list',
        		"data": data,
        		success: function(json,status) {
                             // 一覧情報をセーブ、スペックIDの一覧セレクトを作成
			     var sel = $('#specid');
                             $.data(acc,'specs',json.instance_spec);
                             sel.children().remove();
                             if (json.instance_spec.total > 0) {
                                for(var i = 0;i < json.instance_spec.total;i++)
                                {
                                    var rec = json.instance_spec.results[i].result;
                                    var html = '<option value="' + rec.uuid + '">' + rec.id +'</option>';
                                    sel.append(html);  
                                }
                                // スペックID選択イベント処理を呼出
                                $('#specid').change();
                             } 
                             else
                             {
                                var recs = jQuery("#list").getGridParam("records");
                                for (var i = 1;i <= recs;i++) {
                                    jQuery("#list").delRowData(i);
                                }
                             }
	                }
    		});
        });
        // スペックID選択時処理　
        $('#specid').bind('change',function() {
		var specid = $('#specid').val();
                if (specid != '') {
                        // 追加ドライブ情報をajaxで取得
                        is_uuid = specid;
    			var request = new DcmgrGUI.Request;
                	var data = 'account_id=' + is_accid +'&uuid=' + specid + "&rows=5&page=1&sidx=&sord=asc";
                        // 通信中マスク
                        $("#load_mask1").mask($.i18n.prop('loading_parts'));
    			request.get({
        			"url": '/dialog/get_is_drives_list',
        			"data": data,
        			success: function(json,status) {
                                        // グリッド内容を一端クリアして、取得情報をセット
					var mygrid = jQuery("#list")[0];
                                        jQuery("#list").clearGridData(true);
					mygrid.addJSONData(json);
                                },
                       	 	complete: function(xhr,status) {
                          	    $("#load_mask1").unmask();
                                }
                        }); 
                        // VIF情報をajaxで取得
                	var data2 = 'account_id=' + is_accid +'&uuid=' + specid + "&rows=5&page=1&sidx=&sord=asc";
   			var request2 = new DcmgrGUI.Request;
                        // 通信中マスク
                        $("#load_mask2").mask($.i18n.prop('loading_parts'));
    			request2.get({
        			"url": '/dialog/get_is_vifs_list',
        			"data": data2,
        			success: function(json,status) {
                                        // グリッド内容を一端クリアして、取得情報をセット
					var mygrid = jQuery("#list2")[0];
                                        jQuery("#list2").clearGridData(true);
					mygrid.addJSONData(json);
                                },
                       	 	complete: function(xhr,status) {
                          	    $("#load_mask2").unmask();
                                }
                        }); 
                }      
        });
        
        $('#selaccount_account').change();
    }
  });

  // メイン画面上のボタンの押下処理
  bt_additional_drives_and_IFs.target.bind('click', function() {
    bt_additional_drives_and_IFs.open();
  });
  
  // ---------------------------------インスタンススペック編集・削除ダイアログ-------------------------------
  // ダイアログ内の閉じるボタン処理
  var edit_and_delete_resource_is_buttons = {};
  edit_and_delete_resource_is_buttons[close_button_name] = function() { 
  	$(this).dialog("destroy");
        $(this).remove(); 
  };

  // ダイアログの削除ボタン処理
  edit_and_delete_resource_is_buttons[delete_button_name] = function() {
    // 値を取り込んでリクエスト送信 
    var specid = $(this).find('#specid').val();
    var request = new DcmgrGUI.Request;
    // 送信中葉マスキング
    $("#edit_and_delete_spec_dialog").mask($.i18n.prop('waiting_communicate'));
    request.post({
      "url": '/dialog/delete_is_exec/' + specid,
      success: function(json, status){
         // メッセージボックス「に結果表示
         if (json.result.exitcode == 0) {
            Sexy.messageBox('info',$.i18n.prop(json.result.message));
            bt_edit_and_delete_resource_is.content.dialog("destroy");
            bt_edit_and_delete_resource_is.content.remove();

         } else {
            Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                            "<p>exit code =" + json.result.exitcode  + "</p>" +
                            "<p>" + json.result.detail + "</p>");
         }
      },
      complete: function(xhr,status) {
         $("#edit_and_delete_spec_dialog").unmask();
      }
     });
  }

  // ダイアログの更新ボタン処理
  edit_and_delete_resource_is_buttons[update_button_name] = function() {
    // フォーム全体をバリデーション
    var f = $('#fm');
    var valid = f.validate().form();
    if(valid) {
        // メッセージボックス表示にて結果表示
    	var account_id = $(this).find('#selaccount_account').val();
    	var cpu_cores = $(this).find('#cpu_cores').val();
    	var memory_size = $(this).find('#memory_size').val();
       	var id = $(this).find('#specid').val();
    	var quota_weight = $(this).find('#quota_weight').val();
    	var data ='uuid=' + id 
                  +'&account_id=' + account_id 
		  +'&cpu_cores=' + cpu_cores
                  +'&memory_size='  + memory_size;
        if(quota_weight != '') {
            data = data +'&quota_weight=' + quota_weight;
        }
    	var request = new DcmgrGUI.Request;
        // 送信中はマスキング
        $("#edit_and_delete_spec_dialog").mask($.i18n.prop('waiting_communicate'));
    	request.post({
        	"url": '/dialog/edit_is_exec',
        	"data": data,
        	success: function(json,status) {
                    // メッセージボックス表示にて結果表示
                    if (json.result.exitcode == 0) {
                        Sexy.messageBox('info',$.i18n.prop(json.result.message));
                    	bt_edit_and_delete_resource_is.content.dialog("destroy");
                        bt_edit_and_delete_resource_is.content.remove();

                    } else {
                        Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                                 "<p>exit code =" + json.result.exitcode  + "</p>" +
                                 "<p>" + json.result.detail + "</p>");
                    }
        	},
	        complete: function(xhr,status) {
        	    $("#edit_and_delete_spec_dialog").unmask();
      	        }

    	});
    }
  }
 
  // インスタンススペック編集・削除ダイアログ定義 
  var bt_edit_and_delete_resource_is = new DcmgrGUI.Dialog({
    target: '.edit_and_delete_spec',
    width: 590,
    height: 380,
    title: $.i18n.prop('edit_and_delete_resource_is_header'),
    path: '/edit_and_delete_is',
    button: edit_and_delete_resource_is_buttons,
    callback: function(){      
	var f = $('#fm');
	f.validate({
                // バリデーション定義
    		errorClass : 'valid-error',
    		rules: {
			'cpu_cores' : {	
				required : true,
                        	digits : true,
              			min : 1
			},
			'memory_size' : {	
				required : true,
                        	digits : true,
              			min : 1
			},
			'quota_weight' : {	
                        	number : true,
                                GT : 0
			}
    		},
    		messages: {
			'cpu_cores' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_cpu_cores')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			},
			'memory_size' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_memory_size')]),
                        	digits: $.i18n.prop('validate_errmsg_digits'),
				min: $.validator.format($.i18n.prop('validate_errmsg_min'))
			},
			'quota_weight' : {
                        	number: $.i18n.prop('validate_errmsg_number'),
				GT: $.validator.format($.i18n.prop('validate_errmsg_plus_number'))
			}
    		},
    		onkeyup: false	
  　    });

        // グループ選択時、全インスタンススペック情報をajaxで取得
        $('#selaccount_account').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var account_id = $('#selaccount_account').val();
    		var request = new DcmgrGUI.Request;
                var data = 'account_id=' + account_id;
    		request.post({
        		"url": '/dialog/get_is_list',
        		"data": data,
        		success: function(json,status) {
                             // 一覧情報をセーブ、インスタンススペックIDの一覧セレクトを作成
			     var sel = $('#specid');
                             $.data(acc,'specs',json.instance_spec);
                             sel.children().remove();
                             if (json.instance_spec.total > 0) {
                                for(var i = 0;i < json.instance_spec.total;i++)
                                {
                                    var rec = json.instance_spec.results[i].result;
                                    var html = '<option value="' + rec.uuid + '">' + rec.id +'</option>';
                                    sel.append(html);  
                                }
                                // インスタンススペック選択時処理を呼出
                                $('#specid').change();
                             } 
                             else
                             {
                                // 対象のインスタンススペックがない場合、選択不可にして、画面項目内容クリア
                                var html = '<option value="">' + f.find('#spec_nothing').val()  + '</option>';
                                sel.append(html);
                                f.find('#cpu_cores').val("");
                                f.find(':text').attr("disabled","disabled");
                                f.find('#memory_size').val("");
                                f.find('#quota_weight').val("");
                                $('#arch').html("<BR>");
                                $('#hypervisor').html("<BR>");
  				bt_edit_and_delete_resource_is.disabledButton(1,true);
  				bt_edit_and_delete_resource_is.disabledButton(2,true);
                             }
	                }
    		});
        });
        // インスタンススペック選択時、表示内容を更新
        $('#specid').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var specid = $('#specid').val();
                if (specid != '') {
                        // キャッシュ情報を取り出し
			var instance_spec = $.data(acc,'specs');
                        for (var i = 0;i < instance_spec.total;i++)
                        {
			    var rec = instance_spec.results[i].result;
                            if (specid == rec.uuid) {
                                // 選択されたインスタンススペックなら情報を更新
                                f.find('#cpu_cores').val(rec.cpu_cores);
                                f.find(':text').removeAttr("disabled");
                                f.find('#memory_size').val(rec.memory_size);
                                f.find('#quota_weight').val(rec.quota_weight);
                                $('#arch').html(f.find('#' + rec.arch).val());
                                $('#hypervisor').html(f.find('#' + rec.hypervisor).val());
  				bt_edit_and_delete_resource_is.disabledButton(1,false);
  				bt_edit_and_delete_resource_is.disabledButton(2,false);
                            }
                        }
                }      
        });
        
        $('#selaccount_account').change();
    }
  });

  // メイン画面上のボタン初期化
  $(bt_create_resource_is.target).button({ disabled: false });
  $(bt_additional_drives_and_IFs.target).button({ disabled: false });
  $(bt_edit_and_delete_resource_is.target).button({ disabled: false });

  // ボタン押下時にダイアログを表示
  bt_edit_and_delete_resource_is.target.bind('click', function() {
    bt_edit_and_delete_resource_is.open();
  });

  // ---------------------------------マシンイメージ作成ダイアログ------------------------------------
  // ダイアログ内の閉じるボタン押下
  var create_resource_wmi_buttons = {};
  create_resource_wmi_buttons[close_button_name] = function() {
	$(this).dialog("destroy");
        $(this).remove(); 
  }

  // ダイアログ内の作成ボタン押下
  create_resource_wmi_buttons[create_button_name] = function() { 
    // フォーム全部をバリデーション
    var f = $('#fm');
    var valid = f.validate().form();
    if(valid) {
        // 値を取り込んで、リクエスト送信 
    	var account_id = $(this).find('#selaccount_account').val();
    	var arch = $(this).find('#arch').val();
    	var description = $(this).find('#description').val();
    	var imageid = $(this).find('#imageid').val();
    	var image_location = $(this).find('#image_location').val();
    	var md5sum = $(this).find('#md5sum').val();
    	var data ='account_id=' + account_id 
		  +'&arch=' + arch
                  //+'&is_public=' + is_public
                  +'&imageid=' + imageid
                  +'&description=' + description
                  +'&md5sum=' + md5sum
                  +'&image_location=' + image_location;
    	var request = new DcmgrGUI.Request;
        // 送信中はマスキング
        $("#create_image_dialog").mask($.i18n.prop('waiting_communicate'));
    	request.post({
        	"url": '/dialog/create_wmi_exec',
        	"data": data,
        	success: function(json,status) {
                    // メッセージボックスにて結果表示
                    if (json.result.exitcode == 0) {
                        Sexy.messageBox('info',$.i18n.prop(json.result.message));
			(create_resource_wmi_buttons[close_button_name])();
                    	bt_create_resource_wmi.content.dialog("destroy");
                        bt_create_resource_wmi.content.remove();
                    } else {
                        Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                                 "<p>exit code =" + json.result.exitcode  + "</p>" +
                                 "<p>" + json.result.detail + "</p>");
                    }
        	},
                complete: function(xhr,status) {
                        $("#create_image_dialog").unmask();
                }
   	});
    }
  }
  
  // マシンイメージ作成ダイアログ定義
  var bt_create_resource_wmi = new DcmgrGUI.Dialog({
    target:'.create_machine_image',
    width:583,
    height:520,
    title:$.i18n.prop('create_resource_wmi_header'),
    path:'/create_wmi',
    callback: function(){
        // バリデーション定義
	var f = $('#fm');
	f.validate({
    		errorClass : 'valid-error',
    		rules: {
			'imageid' : {	
				required : true,
                        	AN : true,
                                maxlength : 8
			},
			'description' : {	
              			maxlength : 255
			},
			'image_location' : {	
				required : true,
                        	relativePATH : true,
              			maxlength : 255
			},
                        'md5sum' : {
                                required : true
                        }
    		},
    		messages: {
			'imageid' : {
				required: $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_imageid')]),
                        	AN: $.i18n.prop('validate_errmsg_AN'),
				maxlength: $.validator.format($.i18n.prop('validate_errmsg_maxlength'))
			},
			'description' : {
				maxlength: '<BR>' + $.i18n.prop('validate_errmsg_maxlength')
			},
			'image_location' : {
				required: '<BR>' + $.i18n.prop('validate_errmsg_required',[$.i18n.prop('item_image_location')]),
                        	relativePATH: '<BR>' + $.i18n.prop('validate_errmsg_PATH'),
				maxlength: '<BR>' + $.i18n.prop('validate_errmsg_maxlength')
			},
                        'md5sum' : {
                                required: '<BR>' + $.i18n.prop('validate_errmsg_needs_md5get')
                        }
    		},
    		onkeyup: false,
                onsubmit: false
  　    });
        // md5値取得処理
        f.find('#md5get').click(function() {
            // 取得対象イメージのパス名のバリデーション
    	    var f = $('#fm');
     	    var valid = f.validate().element('#image_location');
            if (valid)
            {
                // イメージパス名を取り込んでリクエスト送信
                var image_location = f.find('#image_location').val();
    	        var request = new DcmgrGUI.Request;
                var data = 'image_location=' + image_location;
                // 送信中はマスキング
                $("#create_image_dialog").mask($.i18n.prop('loading_parts'));
    		request.post({
        	    "url": '/dialog/get_md5sum',
        	    "data": data,
        	    success: function(json,status) {
                        // 成功時は値を取り込み
         	        if (json.result.exitcode == 0) {
                            $('#md5sum').val(json.result.detail)
         		} else {
            		    Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                            		"<p>exit code =" + json.result.exitcode  + "</p>" +
                            		"<p>" + json.result.detail + "</p>");
         		}
                    },
                    complete: function(xhr,status) {
                        $("#create_image_dialog").unmask();
                    }
                }); 
            }
            return false;
        });
        // イメージのパス変更時はmd5値をクリア
        f.find('#image_location').change(function() {
    	    var f = $('#fm');
	    $('#md5sum').val("")
        });
        
    },
    button: create_resource_wmi_buttons
  });
  
  // メイン画面で作成ボタン押下時、ダイアログ表示
  bt_create_resource_wmi.target.bind('click', function(){
    bt_create_resource_wmi.open();
  });
  

  // ---------------------------------マシンイメージ削除ダイアログ------------------------------------
  // ダイアログ内のキャンセルボタン押下
  var delete_resource_wmi_buttons = {};
  delete_resource_wmi_buttons[close_button_name] = function() { 
  	$(this).dialog("destroy");
        $(this).remove(); 
  };

  // ダイアログ内の削除ボタン押下
  delete_resource_wmi_buttons[delete_button_name] = function() {
　  // 値を取り込んでリクエスト送信 
    var imageid = $(this).find('#imageid').val();
    var request = new DcmgrGUI.Request;
    // 送信中はマスキング
    $("#delete_image_dialog").mask($.i18n.prop('waiting_communicate'));
    request.post({
      "url": '/dialog/delete_wmi_exec/' + imageid,
      success: function(json, status){
         // メッセージボックス表示にて結果表示
         if (json.result.exitcode == 0) {
            Sexy.messageBox('info',$.i18n.prop(json.result.message));
            bt_delete_resource_wmi.content.dialog("destroy");
            bt_delete_resource_wmi.content.remove();
         } else {
            Sexy.messageBox('error',"<p>" + $.i18n.prop(json.result.message) + "</p>" +
                            "<p>exit code =" + json.result.exitcode  + "</p>" +
                            "<p>" + json.result.detail + "</p>");
         }
      },
      complete: function(xhr,status) {
         $("#delete_image_dialog").unmask();
      }
   });
  }

  // マシンイメージ削除ダイアログ定義
  var bt_delete_resource_wmi = new DcmgrGUI.Dialog({
    target: '.delete_machine_image',
    width: 600,
    height: 300,
    title: $.i18n.prop('delete_resource_wmi_header'),
    path: '/delete_wmi',
    button: delete_resource_wmi_buttons,
    callback: function(){
        // アカウント選択時、全マシンイメージ情報をajaxで取得      
        $('#selaccount_account').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var account_id = $('#selaccount_account').val();
    		var request = new DcmgrGUI.Request;
                var data = 'account_id=' + account_id;
    		request.post({
        		"url": '/dialog/get_wmi_list',
        		"data": data,
        		success: function(json,status) {
                             // 一覧情報をセーブ、マシンイメージIDの一覧セレクトを作成
			     var sel = $('#imageid');
                             $.data(acc,'machine_images',json.image);
                             sel.children().remove();
                             if (json.image.total > 0) {
                                for(var i = 0;i < json.image.total;i++)
                                {
                                    var rec = json.image.results[i].result;
                                    var html = '<option value="' + rec.uuid + '">' + rec.id + '</option>';
                                    sel.append(html);  
                                }
                                // マシンイメージ選択イベント処理を呼出
                                $('#imageid').change();
                             } 
                             else
                             {
                                // マシンイメージがない場合、選択不可にして、画面項目内容クリア
                                var html = '<option value="">' + f.find('#storagenode_nothing').val()  + '</option>';
                                sel.append(html);
                                $('#arch').html("<BR>");
                                $('#image_location').html("<BR>");
                                $('#description').html("<BR>");
  				bt_delete_resource_wmi.disabledButton(1,true);
                             }
	                }
    		});
        });
        // マシンイメージ選択時、ダイアログ内の項目表示内容を更新
        $('#imageid').bind('change',function() {
                var f = $('#fm');
                var acc = $('#selaccount_account').get(0);
		var imageid = $('#imageid').val();
                if (imageid != '') {
                        // 一覧情報をキャッシュより取り出し
			var image = $.data(acc,'machine_images');
                        for (var i = 0;i < image.total;i++)
                        {
			    var rec = image.results[i].result;
                            // 選択されたマシンイメージの場合、画面内の各項目に値をセット
                            if (imageid == rec.uuid) {
                                $('#arch').html(rec.arch);
                                $('#image_location').html(rec.source);
                                $('#description').html(rec.description);
  				bt_delete_resource_wmi.disabledButton(1,false);
                            }
                        }
                }      
        });
        
        // 初期表示内容で、アカウント選択イベント処理を呼出
        $('#selaccount_account').change();
    }
  });

  // メイン画面のボタン活性化
  $(bt_create_resource_wmi.target).button({ disabled: false });
  $(bt_delete_resource_wmi.target).button({ disabled: false });

  // メイン画面で削除ボタン押下時、ダイアログ表示
  bt_delete_resource_wmi.target.bind('click', function() {
    bt_delete_resource_wmi.open();
  });

}
