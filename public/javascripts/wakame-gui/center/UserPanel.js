// Global Resources
Ext.apply(WakameGUI, {
  User:null,
  UserList:null,
  UserLog:null
});

WakameGUI.User = function(){
  var ulistPanel = new WakameGUI.UserList();
  var ulogPanel  = new WakameGUI.UserLog();
  WakameGUI.User.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [ulistPanel,ulogPanel]
  });
  
  this.refresh = function(){
    ulistPanel.refresh();
    ulogPanel.refresh();
  }
}
Ext.extend(WakameGUI.User, Ext.Panel);

WakameGUI.UserList = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/user-list',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields: [
        { name: 'id' ,type:'string'},
        { name: 'nm' ,type:'string'},
        { name: 'st' ,type:'string'},
        { name: 'en' ,type:'string'},
        { name: 'em' ,type:'string'},
        { name: 'mm' ,type:'string'}
      ]
    })
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "User-ID",    width: 100, dataIndex: 'id', hideable:false, menuDisabled:true },
    { header: "User-Name",  width: 100, dataIndex: 'nm' },
    { header: "State",      width:  80, dataIndex: 'st' },
    { header: "Enable",     width:  60, dataIndex: 'en' },
    { header: "E-Mail",     width: 100, dataIndex: 'em' },
    { header: "Memo",       width: 350, dataIndex: 'mm' }
  ]);

  this.refresh = function(){
    store.reload();
  };
  
  WakameGUI.UserList.superclass.constructor.call(this, {
    region: "center",
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "User Management",
    width: 320,
    split: true,
    autoHeight: false,
    stripeRows: true,
    loadMask: {msg: 'Loading...'},
    bbar: new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    }),
    tbar : [
      { iconCls: 'addUser',
        text : 'Add',handler:function(){
          var addWin = new AddUserWindow();
		  addWin.show();
        }
      },'-',
      { iconCls: 'removeUser',
        text : 'Remove', handler:function(){
          var temp = sm.getCount();
          if(temp > 0){
            Ext.Msg.confirm("Remove:","Are you share?", function(btn){
              if(btn == 'yes'){
                var rec = sm.getSelected();
                store.remove(rec);
              }
            });
          }
        }
      },'-',
      { iconCls: 'editUser',
        text : 'Edit',handler:function(){
		  var temp = sm.getCount();
		  if(temp > 0){
            var data = sm.getSelected();
            var editWin = new EditUserWindow(data);
            editWin.show();
          }
        }
      },'-',
      { iconCls: 'findUser',
        text : 'Search',handler:function(){
          var schWin = new SearchUserWindow();
          schWin.show();
        }
      },'-',
      { iconCls: 'resetUser',
        text : 'Password Reset',handler:function(){
            alert("Password Reset...");
        }
      }
    ]
  });
  store.load({params: {start: 0, limit: 50}});		// limit = page size

  AddUserWindow = function(){
    var form = new Ext.form.FormPanel({
      title: 'User-Infomation',
      labelWidth: 120, 
      width: 400,
      baseCls: 'x-plain',
      items: [
        {
        fieldLabel: 'User-Name',
        xtype: 'textfield',
        name: 'user_name',
        anchor: '100%',
        allowBlank:false
        }
        ,{
        fieldLabel: 'Password',
        xtype: 'textfield',
        inputType : 'password',
        name: 'password',
        anchor: '100%',
        allowBlank:false
        }
        ,{
        fieldLabel: 'E-Mail',
        xtype: 'textfield',
        name: 'email',
        anchor: '100%',
        allowBlank:false
        }
        ,{
        fieldLabel: 'enable',
        xtype: 'checkbox',
        width: 100,
        name: "enable",
        checked : true
        }
        ,{
        fieldLabel: 'Memo',
        xtype: 'textarea',
        name: 'memo',
        anchor: '100%'
        }
      ],buttons: [{
        text:'Save',
        handler: function(){
          form.getForm().submit({
            url: '/user-create',
            waitMsg: 'Saveing...',
            method: 'POST',
            scope: this,
            success: function(form, action) {
              refresh();
              this.close();
            },
            failure: function(form, action) {
              alert('Add user failure.');
              this.close();
            }
          });
        },
        scope:this
      },{
        text: 'Close',
        handler: function(){
          this.close();
        },
        scope:this
      }]      
    });

    var myData = {
		records : [
			{ name : "12837549402300", column1 : "AXSH(SOUMU)" },
			{ name : "83948393933331", column1 : "AXSH(EIGYO)" },
			{ name : "13983343933113", column1 : "Yaboo" },
			{ name : "13977743933223", column1 : "Coocle" },
			{ name : "25447689654556", column1 : "Damazon" },
			{ name : "25447689654557", column1 : "fffff" },
			{ name : "54476896545566", column1 : "ggggg" },
			{ name : "54476896545567", column1 : "hhhhhh" },
			{ name : "54476896545568", column1 : "iiiiiii" },
			{ name : "54476896545569", column1 : "jjjjjjj" }
		]
	};

	var fields = [
		{name: 'account-id',   mapping : 'name'   },
		{name: 'account-name', mapping : 'column1'}
	];

    var ds1 = new Ext.data.JsonStore({
        fields : fields,
		data   : myData,
		root   : 'records'
    });

	var cols = [
		{ id : 'name', header: "Account-ID", width: 100, sortable: true, dataIndex: 'account-id'},
		{              header: "Account-Name", width:100, sortable: true, dataIndex: 'account-name'}
	];

    var grid1 = new Ext.grid.GridPanel({
	    ddGroup          : 'ddGroup2',
        style            : 'padding:0;',
        store            : ds1,
        columns          : cols,
	    enableDragDrop   : true,
        stripeRows       : true,
        autoExpandColumn : 'name'
    });

    var ds2 = new Ext.data.JsonStore({
        fields : fields,
		root   : 'records'
    });

    var grid2 = new Ext.grid.GridPanel({
	    ddGroup          : 'ddGroup2',
        style            : 'padding:0;',
        store            : ds2,
        columns          : cols,
	    enableDragDrop   : true,
        stripeRows       : true,
        autoExpandColumn : 'name'
    });

    var account = new Ext.Panel({
      title : 'Account',
	  layout: 'hbox',
      baseCls: 'x-plain',
	  defaults     : { flex : 1 }, //auto stretch
	  layoutConfig : { align : 'stretch' },
      items : [grid1,grid2],
      tbar : [
        { text : 'Search Account-ID',
          handler:function(){
            var schWin = new SearchAccountWindow();
		    schWin.show();
          }
        }
      ]
    });

    var ds3 = new Ext.data.SimpleStore({
      fields : ["ID","Tag-Name"],
      data : [
        [1,"Instance.Read"],
        [2,"Instance.Write"],
        [3,"WMI.Exec"],
        [4,"WMI.Stop"]
      ]
    });

    var list1 = new Ext.ListView({
      title            : 'Available',
	  ddGroup          : 'ddGroup3',
      multiSelect      : true,
      width            : 200,
      style            : 'padding:0;',
      store            : ds3,
	  enableDragDrop   : true,
      columns: [{
        header: 'Tag-ID',
        width: .3,
        dataIndex: 'ID'
      },{
        header: 'Rool',
        dataIndex: 'Tag-Name',
      }]
    });

    var ds4 = new Ext.data.SimpleStore({
      fields : ["ID","Tag-Name"]
    });

    var list2 = new Ext.ListView({
      title            : 'Selected',
 	  ddGroup          : 'ddGroup4',
      width            : 200,
      multiSelect      : false,
      style            : 'padding:0;',
      store            : ds4,
	  enableDragDrop   : true,
      columns: [{
        header: 'Tag-ID',
        width: .3,
        dataIndex: 'id'
      },{
        header: 'Rool',
        dataIndex: 'name',
      }]
    });

    var dsUserProfile = new Ext.data.SimpleStore({
      fields : ["Account-Name","ID"],
      data : [
        ["Axsh(Soumu)","1"],
        ["Axsh(Eigyo)","2"],
        ["Damazon","3"],
        ["yaboo","4"]
      ]
    });

    var tags = new Ext.Panel({
      title: 'TAGs',
	  layout: 'hbox',
	  defaults     : { flex : 1 }, //auto stretch
	  layoutConfig : { align : 'stretch' },
      items : [list1,list2],
      tbar: [{
        xtype: 'combo',
        editable: false,
        id: 'cmbUserProfile',
        store: dsUserProfile,
        mode: 'local',
        width: 100,
        triggerAction: 'all',
        displayField: 'Account-Name',
        value:'1',
        valueField: 'ID'
      }]
    });

    var tabwin = new Ext.TabPanel({
      activeTab: 0, 
      baseCls: 'x-plain',
      defaults:{bodyStyle:'padding:5px'},
      items: [form,account,tags]
    });

    AddUserWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      width: 500,
      height: 400,
      closeAction:'hide',
      title: 'Add User',
      plain: true,
      layout:'fit',
      items: [tabwin]
    });
  }
  Ext.extend(AddUserWindow, Ext.Window);

  EditUserWindow = function(userData){
    var form = new Ext.form.FormPanel({
      title: 'User-Infomation',
      labelWidth: 120, 
      width: 400,
      baseCls: 'x-plain',
	  buttons: [
	    {
			text: 'Password Reset',
			handler: function(){
              alert("Password Reset...");
			},
			scope:this
	    }
      ],
      items: [
        {
        fieldLabel: 'User-ID',
        xtype: 'displayfield',
        name: 'form_textfield',
        value: userData.get('user-id'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'User-Name',
        xtype: 'textfield',
        name: 'form_textfield',
        value: userData.get('user-name'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'E-Mail',
        xtype: 'textfield',
        name: 'form_textfield',
        value: userData.get('e-mail'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Enable',
        xtype: 'checkbox',
        width: 100,
	    name: "enable",
        boxLabel: '',
        checked : userData.get('enable')=='true'?true:false
        }
        ,{
        fieldLabel: 'Memo',
        xtype: 'textarea',
        name: 'form_textfield',
        value: userData.get('memo-text'),
        anchor: '100%'
        }
      ]
    });

    var account = new Ext.Panel({
      title: 'Account',
      html: 'Account Selecter'
    });

    var tags = new Ext.Panel({
      title: 'TAGs',
      layout:'fit',
      html: 'TAGs Selecter'
    });

    var tabwin = new Ext.TabPanel({
      baseCls: 'x-plain',
      activeTab: 0, 
      items: [form,account,tags]
    });

    EditUserWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      modal: true,
      width: 500,
      height: 400,
      closeAction:'hide',
      title: 'Edit User',
      plain: true,
      layout:'fit',
      defaults:{bodyStyle:'padding:15px'},
      items: [tabwin],
      buttons: [{
        text:'Save'
      },{
        text: 'Close',
        handler: function(){
          this.close();
        },
        scope:this
      }]
    });
  }
  Ext.extend(EditUserWindow, Ext.Window);

  SearchUserWindow = function(){
    var form = new Ext.form.FormPanel({
      width: 400,
      frame:true,
      bodyStyle:'padding:5px 5px 0',
      items: [{
        layout:'column',
        items:[{
          columnWidth:.7,
          layout: 'form',
          items: [{
            fieldLabel: 'User-ID',
            xtype: 'textfield',
            name: 'account-id',
            anchor: '100%'
          }, {
            fieldLabel: 'User-Name',
            xtype: 'textfield',
            name: 'account-name',
            anchor: '100%'
          }, {
            fieldLabel: 'E-Mail',
            xtype: 'textfield',
            name: 'account-name',
            vtype:'email',
            anchor: '100%'
          }, {
            fieldLabel: 'Enable',
            xtype: 'checkbox',
            anchor: '100%',
            items: [{
	          name: "enable",
              boxLabel: 'Enable',
              checked : true
	        }]
          }, {
            fieldLabel: 'Account-ID',
            xtype: 'displayfield',
            name: 'account-id',
            anchor: '100%'
          }]
        },{
          labelWidth: 5, 
          columnWidth:.3,
          layout: 'form',
          items: [{
            xtype: 'combo',
            editable: false,
            anchor: '100%',
            forceSelection:true,
            mode: 'local',
            store: new Ext.data.ArrayStore({
              id: 1,
              fields: [
                'myId',
                'displayText'
              ],
              data: [[1,'without'],[2, 'exact'], [3, 'include']]
            }),
            triggerAction: 'all',
		    value:'1',
            valueField: 'myId',
            displayField: 'displayText'
          },{
            xtype: 'combo',
            editable: false,
            anchor: '100%',
            forceSelection:true,
            mode: 'local',
            store: new Ext.data.ArrayStore({
              id: 1,
              fields: [
                'myId',
                'displayText'
              ],
              data: [[1,'without'],[2, 'exact'], [3,'include']]
            }),
            triggerAction: 'all',
		    value:'1',
            valueField: 'myId',
            displayField: 'displayText'
          },{
            xtype: 'combo',
            editable: false,
            anchor: '100%',
            forceSelection:true,
            mode: 'local',
            store: new Ext.data.ArrayStore({
              id: 1,
              fields: [
                'myId',
                'displayText'
              ],
              data: [[1,'without'],[2, 'exact'], [3,'include']]
            }),
            triggerAction: 'all',
		    value:'1',
            valueField: 'myId',
            displayField: 'displayText'
          },{
            xtype: 'combo',
            editable: false,
            anchor: '100%',
            forceSelection:true,
            mode: 'local',
            store: new Ext.data.ArrayStore({
              id: 1,
              fields: [
                'myId',
                'displayText'
              ],
              data: [[1, 'without'], [2, 'use']]
            }),
            triggerAction: 'all',
		    value:'1',
            valueField: 'myId',
            displayField: 'displayText'
          },{
            xtype: 'combo',
            editable: false,
            anchor: '100%',
            forceSelection:true,
            mode: 'local',
            store: new Ext.data.ArrayStore({
              id: 1,
              fields: [
                'myId',
                'displayText'
              ],
              data: [[1, 'without'], [2, 'use']]
            }),
            triggerAction: 'all',
		    value:'1',
            valueField: 'myId',
            displayField: 'displayText'
          }]
        }]
      }]
    });
    SearchUserWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      height: 220,
      width: 500,
      layout:'fit',
      title: 'Search User',
      items: [form],
      buttons: [{
        text:'Get Account-ID',
		handler: function(){
          alert('Get Account-ID !!!')
		},
		scope:this
		},{
		text:'Load Query',
		handler: function(){
          alert('Load Query !!!')
		},
		scope:this
		},{
		text:'Save Query',
		handler: function(){
          alert('Save Query !!!')
		},
		scope:this
		},{
		text:'OK',
		handler: function(){
		  this.close();
		},
		scope:this
		},{
		text: 'Cancel',
		handler: function(){
		  this.close();
		},
		scope:this
      }]
    });
  }
  Ext.extend(SearchUserWindow, Ext.Window);
}
Ext.extend(WakameGUI.UserList, Ext.grid.GridPanel);

WakameGUI.UserLog = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'action' },
      { name: 'date-time' },
      { name: 'target' },
      { name: 'account-name' },
      { name: 'message' }
    ],
    data:[
      [ 'lauch', '2009/12/1 11:10:10' , 'instance',  'axsh_soumu', 'xxxxx'],
      [ 'save',  '2009/12/2 15:00:20' ,  'wmi',      'axsh_eigyo', 'xxxxx'],
      [ 'stop' , '2009/12/3 19:00:05' , 'instance',  'axsh_soumu', 'xxxxx']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "DateTime",    width: 150, dataIndex: 'date-time' },
    { header: "Action",      width: 100, dataIndex: 'action'   },
    { header: "Target",      width: 100, dataIndex: 'target'    },
    { header: "Account-Name",width: 100, dataIndex: 'account-name'  },
    { header: "Message",     width: 350, dataIndex: 'message' }
  ]);
  
  this.refresh = function(){
    //store.reload();
  };

  WakameGUI.UserLog.superclass.constructor.call(this, {
    region: "south",
    title: 'Log',
    cm:clmnModel,
    sm:sm,
    split: true,
    height: 200,
    store: store,
    stripeRows: true,
    collapsed:false,
    collapsible:true,
    titleCollapse:true,
    animCollapse:true,
    loadMask: {msg: 'Loading...'},
    bbar: new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(WakameGUI.UserLog, Ext.grid.GridPanel);