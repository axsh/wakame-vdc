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
            Ext.Msg.confirm("Remove:","Are you sure?", function(btn){
              if(btn == 'yes'){
                Ext.Ajax.request({
                  url: '/user-remove',
                  method: "POST", 
                  params : 'id=' + sm.getSelected().id,
                  success: function(form, action) {
                    store.reload();
                  }
                });
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
    var user = new Ext.form.FormPanel({
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
          user.getForm().submit({
            url: '/user-create',
            waitMsg: 'Saveing...',
            method: 'POST',
            scope: this,
            success: function(form, action) {
              store.reload();
              this.close();
            },
            failure: function(form, action) {
              WakameGUI.formsFailureBox(form);
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

    var dsUserProfile = new Ext.data.SimpleStore({
      fields : ["Account-Name","ID"],
      data : [
        ["Axsh(Soumu)","1"],
        ["Axsh(Eigyo)","2"],
        ["Damazon","3"],
        ["yaboo","4"]
      ]
    });

    var tabwin = new Ext.TabPanel({
      activeTab: 0, 
      baseCls: 'x-plain',
      defaults:{bodyStyle:'padding:5px'},
      items: [user]
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
    var user = new Ext.form.FormPanel({
      title: 'User-Infomation',
      labelWidth: 120, 
      width: 400,
      baseCls: 'x-plain',
	  buttons: [{
        text:'Edit',
        handler: function(){
          user.getForm().submit({
            url: '/user-edit',
            waitMsg: 'Editing...',
            method: 'POST',
            scope: this,
            success: function(form, action) {
              store.reload();
              this.close();
            },
            failure: function(form, action) {
              WakameGUI.formsFailureBox(form);
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
      }],
      items: [
        {
        fieldLabel: 'User-ID',
        xtype: 'displayfield',
        name: 'id',
        value: userData.get('id'),
        anchor: '100%'
        }
        ,{
        xtype: 'hidden',
        name: 'user_id',
        value: userData.get('id'),
        }
        ,{
        fieldLabel: 'User-Name',
        xtype: 'textfield',
        name: 'user_name',
        value: userData.get('nm'),
        anchor: '100%',
        allowBlank:false
        }
        ,{
        fieldLabel: 'E-Mail',
        xtype: 'textfield',
        name: 'email',
        value: userData.get('em'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Enable',
        xtype: 'checkbox',
        width: 100,
	    name: "enable",
        boxLabel: '',
        checked : userData.get('en')=='true'?true:false
        }
        ,{
        fieldLabel: 'Memo',
        xtype: 'textarea',
        name: 'memo',
        value: userData.get('mm'),
        anchor: '100%'
        }
      ]
    });
    
    //Account
    var a_fields = [
		{name: 'account-id',   mapping : 'name'   },
		{name: 'account-name', mapping : 'column1'}
	];

    var sa1 = new Ext.data.JsonStore({
        fields : a_fields,
		data   : {
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
    	},
		root   : 'records'
    });

    var sa2 = new Ext.data.JsonStore({
        fields : a_fields,
		root   : 'records'
    });

	var a_cols = [
		{ id : 'name', header: "Account-ID", width: 100, sortable: true, dataIndex: 'account-id'},
		{              header: "Account-Name", width:100, sortable: true, dataIndex: 'account-name'}
	];
        
    var account = new Ext.Panel({
      title: 'Account',
      layout: 'hbox',
      baseCls: 'x-plain',
      defaults     : { flex : 1 }, //auto stretch
      layoutConfig : { align : 'stretch' },
            items : [
            new Ext.grid.GridPanel({
        	    ddGroup          : 'ddGroup2',
                style            : 'padding:0;',
                store            : sa1,
                columns          : a_cols,
        	    enableDragDrop   : true,
                stripeRows       : true,
                autoExpandColumn : 'name'
            }),
            new Ext.grid.GridPanel({
        	    ddGroup          : 'ddGroup2',
                style            : 'padding:0;',
                store            : sa2,
                columns          : a_cols,
        	    enableDragDrop   : true,
                stripeRows       : true,
                autoExpandColumn : 'name'
            })],
            tbar : [
              { text : 'Search Account-ID',
                handler:function(){
                  var schWin = new SearchAccountWindow();
                 schWin.show();
                }
              }
            ],
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
    
    //Role
    var r_fields = [
		{name: 'role-id',   mapping : 'role'   }
	];

    var sr1 = new Ext.data.JsonStore({
        fields : r_fields,
		data   : {
    		records : [
    		      { role : "RunInstance" },
                  { role : "ShutdownInstance" },
                  { role : "CreateAccount" },
                  { role : "DestroyAccount" },
                  { role : "CreateImageStorage" },
                  { role : "GetImageStorage" },
                  { role : "DestroyImageStorage" },
                  { role : "CreateImageStorageHost" },
                  { role : "DestroyImageStorageHost" },
                  { role : "CreatePhysicalHost" },
                  { role : "DestroyPhysicalHost" },
                  { role : "CreateHvController" },
                  { role : "DestroyHvController" },
                  { role : "CreateHvAgent" },
                  { role : "DestroyHvAgent" }
    		]
    	},
		root   : 'records'
    });

    var sr2 = new Ext.data.JsonStore({
        fields : r_fields,
		root   : 'records'
    });

	var r_cols = [
		{ id : 'role-id', header: "Role", width: 100, sortable: true, dataIndex: 'role-id'}
	];
        
    var role = new Ext.Panel({
      title: 'Role',
      layout: 'hbox',
      baseCls: 'x-plain',
      defaults     : { flex : 1 }, //auto stretch
      layoutConfig : { align : 'stretch' },
            items : [
            new Ext.grid.GridPanel({
        	    ddGroup          : 'ddGroup2',
                style            : 'padding:0;',
                store            : sr1,
                columns          : r_cols,
        	    enableDragDrop   : true,
                stripeRows       : true,
                autoExpandColumn : 'role-id'
            }),
            new Ext.grid.GridPanel({
        	    ddGroup          : 'ddGroup2',
                style            : 'padding:0;',
                store            : sr2,
                columns          : r_cols,
        	    enableDragDrop   : true,
                stripeRows       : true,
                autoExpandColumn : 'role-id'
            })],
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

    var tabwin = new Ext.TabPanel({
      baseCls: 'x-plain',
      activeTab: 0, 
      items: [user,account,role]
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
      items: [tabwin]
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
    // store.reload();
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