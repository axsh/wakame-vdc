/*
	Wakame GUI		-*- coding: utf-8 -*-
*/
var centerPanel = null;
var panelMode = 0;
var querySelect = 0;

Ext.onReady(function(){
  Ext.BLANK_IMAGE_URL='./javascripts/ext-js/resources/images/default/s.gif';
  Ext.QuickTips.init();

  centerPanel    = new MainPanel();
  var westPanel  = new WestPanel();
  var northPanel = new NorthPanel('DataCenter Manager');
  var southPanel = new SouthPanel();
  viewport       = new Ext.Viewport({
    layout: 'border',
    items:[ northPanel, centerPanel, westPanel, southPanel]
  });
});

function ChangePanel(md)
{
  if(panelMode != md){
    panelMode = md;
    centerPanel.layout.setActiveItem(panelMode);
  }
}

function ChangeQuery(md)
{
  if(querySelect != md){
    querySelect = md;
  }
}

WestPanel = function(){
  WestPanel.superclass.constructor.call(this,{
    region: "west",
    split: true,
    header: false,
    border: false,
    useArrows:true,
    enableDD:false,
    collapsed:false,
    collapsible:true,
    titleCollapse:true,
    animCollapse:true,
    width: 160,
    listeners: {
      'click': function(node){
          if(node.id == 'menu01'){
            ChangePanel(0);
          }
          else if(node.id == 'menu02'){
            ChangePanel(1);
          }
          else if(node.id == 'menu03'){
            ChangePanel(2);
          }
          else if(node.id == 'menu04'){
            ChangePanel(3);
          }
          else if(node.id == 'menu05'){
            ChangePanel(4);
          }
          else if(node.id == 'menu06'){
            ChangePanel(5);
          }
      }
    },
    rootVisible: false,
    root:{
      text:      '',
      draggable: false,
      id:        'root',
      expanded:  true,
      children:  [
        {
          id:       'child1',
          text:     'Manage',
          expanded:  true,
          children:  [
            {
              id:       'menu01',
              text:     'Account Management',
              leaf:     true
            },
            {
              id:       'menu02',
              text:     'User Management',
              leaf:     true
            }
          ]
        },
        {
          id:       'child2',
          text:     'Resource',
          expanded:  true,
          children:  [
            {
              id:       'menu03',
              text:     'Viewer',
              leaf:     true
            }
            ,{
              id:       'menu04',
              text:     'Editor',
              leaf:     true
            }
            ,{
              id:       'menu05',
              text:     'Location Map',
              leaf:     true
            }
          ]
        },
        {
          id:       'child3',
          text:     'Log',
          expanded:  true,
          children:  [
            {
              id:       'menu06',
              text:     'Log Viewer',
              leaf:     true
            }
          ]
        }
      ]
    }
  });
}
Ext.extend(WestPanel, Ext.tree.TreePanel);

MainPanel = function(){
  var amPanel = new AMPanel();
  var umPanel = new UMPanel();
  var mapPanel = new MAPPanel();
  var rEditPanel = new ResourceEditorPanel();
  var rViewerPanel = new ResourceViewerPanel();
  var centerLogPanel = new CenterLogPanel();

  MainPanel.superclass.constructor.call(this, {
	region:'center',
	layout:'card',
	activeItem: 0,
	defaults: {
	  border:false
	},
	items: [amPanel,umPanel,rViewerPanel,rEditPanel,mapPanel,centerLogPanel]
  });
}
Ext.extend(MainPanel, Ext.Panel);

AMPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var addWin = null;
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/account-list',
//    url: './account.json',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id' ,type:'string'},
        { name:'nm' ,type:'string'},
        { name:'en' ,type:'string'},
        { name:'rg' ,type:'string'},
        { name:'cn' ,type:'string'},
        { name:'mm' ,type:'string'}
      ]
    })
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Account-ID"    , width: 120, dataIndex: 'id' , hideable:false, menuDisabled:true },
    { header: "Account-Name"  , width: 120, dataIndex: 'nm' , sortable: true },
    { header: "Enable"        , width: 60,  dataIndex: 'en' },
    { header: "Registered"    , width: 80,  dataIndex: 'rg' , sortable: true},
    { header: "Contract-Date" , width: 80,  dataIndex: 'cn' , sortable: true },
    { header: "Memo"          , width: 300, dataIndex: 'mm' }
  ]);

  AMPanel.superclass.constructor.call(this, {
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "Account Management",
    width: 320,
    autoHeight: false,
    stripeRows: true,
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
          if(addWin == null){
            addWin = new AddAccountWindow();
          }
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
			var editWin = new EditAccountWindow(data);
			editWin.show();
          }
        }
      },'-',
      { iconCls: 'findUser',
        text : 'Search',handler:function(){
          var schWin = new SearchAccountWindow();
		  schWin.show();
        }
      }
    ]
  });
  store.load({params: {start: 0, limit: 50}});		// limit = page size
}
Ext.extend(AMPanel, Ext.grid.GridPanel);

UMPanel = function(){
  var ulistPanel = new UListPanel();
  var ulogPanel  = new ULOGPanel();

  UMPanel.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [ulistPanel,ulogPanel]
  });
}
Ext.extend(UMPanel, Ext.Panel);

UListPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});

  var store = new Ext.data.Store({
    url: '/user.json',
//    url: '/user-list',
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
  store.load();

  var addWin = null;
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "User-ID",    width: 100, dataIndex: 'id', hideable:false, menuDisabled:true },
    { header: "User-Name",  width: 100, dataIndex: 'nm' },
    { header: "State",      width:  80, dataIndex: 'st' },
    { header: "Enable",     width:  60, dataIndex: 'en' },
    { header: "E-Mail",     width: 100, dataIndex: 'em' },
    { header: "Memo",       width: 350, dataIndex: 'mm' }
  ]);

  UListPanel.superclass.constructor.call(this, {
    region: "center",
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "User Management",
    width: 320,
    split: true,
    autoHeight: false,
    stripeRows: true,
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    }),
    tbar : [
      { iconCls: 'addUser',
        text : 'Add',handler:function(){
          if(addWin == null){
            addWin = new AddUserWindow();
          }
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
}
Ext.extend(UListPanel, Ext.grid.GridPanel);

ULOGPanel = function(){

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

  ULOGPanel.superclass.constructor.call(this, {
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
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
   });
}
Ext.extend(ULOGPanel, Ext.grid.GridPanel);


AddAccountWindow = function(){
  var form = new Ext.form.FormPanel({
    labelWidth: 120, 
    width: 400, 
    baseCls: 'x-plain',
    items: [
      {
      fieldLabel: 'Account-Name',
      xtype: 'textfield',
      id: 'nm',
      anchor: '100%'
      }
      ,{
      fieldLabel: '',
      id: 'en',
      xtype: 'checkboxgroup',
      items: [
        {boxLabel: 'Enable',    name: 'enable'}
      ]
      }
      ,{
      fieldLabel: 'Contract-Date',
      xtype: 'datefield',
      id: 'cn',
      anchor: '100%'
      }
      ,{
      fieldLabel: 'Memo',
      xtype: 'textarea',
      id: 'mm',
      anchor: '100%'
      }
    ]
  });

  AddAccountWindow.superclass.constructor.call(this, {
        iconCls: 'icon-panel',
        collapsible:true,
        titleCollapse:true,
        width: 500,
        height: 250,
		layout:'fit',
		closeAction:'hide',
        title: 'Add Account',
		modal: true,
		plain: true,
        defaults:{bodyStyle:'padding:15px'},

		items: [form],
		buttons: [{
		  text:'Create',
          handler: submit
		},{
		  text: 'Close',
		  handler: function(){
		    this.hide();
		  },
		  scope:this
		}]
  });
  function submit(){
    form.getForm().submit({
      url: '/account-create',
      method: 'POST',
      success: function(form, action) {
        alert( action.response.responseText );
	    this.close();
      },
      failure: function(form, action) {
        alert( action.failureType );
	    this.close();
      }
    });
  }
}
Ext.extend(AddAccountWindow, Ext.Window);

EditAccountWindow = function(accountData){
   var form = new Ext.form.FormPanel({
      labelWidth: 120, 
      width: 400, 
      baseCls: 'x-plain',
      items: [
        {
        fieldLabel: 'Account-ID',
        xtype: 'displayfield',
        name: 'form_textfield',
        value: accountData.get('account-id'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Account-Name',
        xtype: 'textfield',
        name: 'form_textfield',
        value: accountData.get('account-name'),
        anchor: '100%'
        }
        ,{
        fieldLabel: '',
        xtype: 'checkboxgroup',
        items: [
          { boxLabel: 'Enable',
            name: 'enable',
            checked: accountData.get('enable')=='true'?true:false
          }
        ]
        }
        ,{
        fieldLabel: 'Contract-Date',
        xtype: 'textfield',
        name: 'contract-date',
        value: accountData.get('contract-date'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Memo',
        xtype: 'textarea',
        name: 'form_textarea',
        value: accountData.get('memo-text'),
        anchor: '100%'
        }
      ]
    });

    EditAccountWindow.superclass.constructor.call(this, {
        iconCls: 'icon-panel',
        collapsible:true,
        titleCollapse:true,
        width: 500,
        height: 250,
		layout:'fit',
//		closeAction:'hide',
        title: 'Edit Account',
		modal: true,
		plain: true,
        defaults:{bodyStyle:'padding:15px'},
		items: [form],
		buttons: [{
			text:'Create',
			handler: function(){
				this.close();
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
}
Ext.extend(EditAccountWindow, Ext.Window);

SearchAccountWindow = function(){
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
            fieldLabel: 'Account-ID',
            xtype: 'textfield',
            name: 'account-id',
            anchor: '100%'
          }, {
            fieldLabel: 'Account-Name',
            xtype: 'textfield',
            name: 'account-name',
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
            fieldLabel: 'Contract-Date',
            xtype: 'datefield',
            name: 'contract-date',
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
              data: [[1,'without'],[2, 'before'], [3, 'after']]
            }),
            triggerAction: 'all',
		    value:'1',
            valueField: 'myId',
            displayField: 'displayText'
          }]
        }]
      }]
    });

    SearchAccountWindow.superclass.constructor.call(this, {
        iconCls: 'icon-panel',
        height: 220,
        width: 500,
		layout:'fit',
        title: 'Search Account',
		items: [form],
		buttons: [{
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
Ext.extend(SearchAccountWindow, Ext.Window);

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
        name: 'form_textfield',
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Password',
        xtype: 'textfield',
        inputType : 'password',
        name: 'form_textfield',
        anchor: '100%'
        }
        ,{
        fieldLabel: 'E-Mail',
        xtype: 'textfield',
        name: 'form_textfield',
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Enable',
        xtype: 'checkbox',
        width: 100,
          items: [{
	        name: "enable",
            boxLabel: 'Enable',
            checked : true
	      }]
        }
        ,{
        fieldLabel: 'Memo',
        xtype: 'textarea',
        name: 'form_textfield',
        anchor: '100%'
        }
      ]
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

	// declare the source Grid
    var grid1 = new Ext.grid.GridPanel({
	    ddGroup          : 'ddGroup2',
//      title            : 'Available',
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

    // create the destination Grid
    var grid2 = new Ext.grid.GridPanel({
	    ddGroup          : 'ddGroup2',
//      title            : 'Selected',
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
        items: [tabwin],
		buttons: [{
			text:'Save',
		},{
			text: 'Close',
			handler: function(){
				this.hide();
			},
			scope:this
		}]

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
			text:'Save',
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

MAPPanel = function(){
  var mPropertyPanel = new MAPPropertyPanel();
  var mtabPanel  = new MAPTabPanel('center',600);
  mtabPanel.add(new MAPViewPanel('1F-100'));
  mtabPanel.add(new MAPViewPanel('1F-101'));
  mtabPanel.add(new MAPViewPanel('2F-101'));
  mtabPanel.add(new MAPViewPanel('2F-200'));
  mtabPanel.add(new MAPViewPanel('3F-105'));
  mtabPanel.add(new MAPViewPanel('3F-200'));

  MAPPanel.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [mtabPanel,mPropertyPanel],
    tbar : [
      { text : 'Add Map',
        handler:function(){
          var addmap = new AddMapWindow();
		  addmap.show();
        }
      },
      { text : 'Remove',handler:function(){
          alert('Remove');
         }
      },
      { text : 'Edit',handler:function(){
          alert('Edit');
        }
      }
    ]
  });
}
Ext.extend(MAPPanel, Ext.Panel);

MAPTabPanel = function(posi,size){
  MAPTabPanel.superclass.constructor.call(this, {
    split: true,
    region: posi,
    width: size,
    activeTab: 0
  });
}
Ext.extend(MAPTabPanel, Ext.TabPanel);

MAPViewPanel = function(name){
  MAPViewPanel.superclass.constructor.call(this, {
    region: 'center',
    title: name,
    autoScroll: true,
    split: true,
    layout: 'fit',
    html: '<img src="1F-10.jpeg">'
//  bodyStyle: "background-image:url(1F-10.jpeg); background-repeat: no-repeat; background-attachment: fixed;"
  });
}
Ext.extend(MAPViewPanel, Ext.Panel);

MAPPropertyPanel = function(){
  MAPPropertyPanel.superclass.constructor.call(this, {
    region: 'east',
    title: "Property",
    split: true,
    width: 150,
    collapsed:false,
    collapsible:true,
    titleCollapse:true,
    animCollapse:true,
    bodyStyle:'padding:15px',
    html: 'Memo:xxxx'
  });
}
Ext.extend(MAPPropertyPanel, Ext.Panel);

ResourceViewerPanel = function(){
  var serverquery = new ServerQueryPanel();
  var serverlist  = new ServerListPanel();
  var mtabPanel  = new MAPTabPanel('east',250);

  mtabPanel.add(new MAPViewPanel('1F-100'));
  mtabPanel.add(new MAPViewPanel('1F-101'));

  ResourceViewerPanel.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [serverquery,serverlist,mtabPanel]
  });
}
Ext.extend(ResourceViewerPanel, Ext.Panel);

ServerListPanel = function(){
  var rackPanel = new RackPanel();
  var hwPanel   = new HWPanel();
  var hvcPanel  = new HVCPanel();
  var hvaPanel  = new HVAPanel();
  var vmPanel   = new VMPanel();
  ServerListPanel.superclass.constructor.call(this, {
    split: true,
    region: 'center',
    activeTab: 0, 
    items: [rackPanel,hwPanel,hvcPanel,hvaPanel,vmPanel]
  });
}
Ext.extend(ServerListPanel, Ext.TabPanel);

HWPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'server-id'       },
      { name: 'cpu_model'       },
      { name: 'cpu_mhz'         },
      { name: 'memory'          },
      { name: 'hypervisor_type' },
      { name: 'ip-address'      },
      { name: 'hvc-address'     },
      { name: 'rack-name'       },
      { name: 'pool'            },
      { name: 'location'        },
      { name: 'memo'            }
    ],
    data:[ 
      [ 'S1001', 'x386', '2GHz', '3GB', 'HVC', '192.168.1.1', '','R1001','TEST','1F2001','Test Server']
    ]
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Server-ID"  , width: 100, dataIndex: 'server-id'   },
    { header: "CPU"  , width: 100, dataIndex: 'cpu_model'   },
    { header: "Hz"   , width: 100, dataIndex: 'cpu_mhz'   },
    { header: "Memory"   , width: 100, dataIndex: 'memory'   },
    { header: "Type"    , width: 100, dataIndex: 'hypervisor_type'   },
    { header: "IP-address"  , width: 100, dataIndex: 'ip-address'   },
    { header: "HVC-address"  , width: 100, dataIndex: 'hvc-address'   },
    { header: "Rack-Name", width: 150, dataIndex: 'rack-name' },
    { header: "Pool", width: 150, dataIndex: 'pool' },
    { header: "Location" , width: 150, dataIndex: 'location'  },
    { header: "Memo"     , width: 150, dataIndex: 'memo'      }
  ]);

  HWPanel.superclass.constructor.call(this, {
    title: "Server",
    listeners: {activate:function() { ChangeQuery(3);} },
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(HWPanel, Ext.grid.GridPanel);

RackPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'rack-id'   },
      { name: 'rack-name' },
      { name: 'location'  },
      { name: 'memo'      }
    ],
    data:[ 
      [ '1001', 'AA001', '1F-1001', 'for test'],
      [ '1002', 'AA002', '1F-1001', 'for test'],
      [ '1003', 'AA003', '1F-1001', 'for test'],
      [ '1004', 'AA004', '1F-1001', 'for test'],
      [ '1005', 'AB001', '2F-1001', 'for test'],
      [ '1006', 'AB002', '2F-1001', 'for test']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Rack-ID"  , width: 100, dataIndex: 'rack-id'   },
    { header: "Rack-Name", width: 150, dataIndex: 'rack-name' },
    { header: "location" , width: 150, dataIndex: 'location'  },
    { header: "Memo"     , width: 150, dataIndex: 'memo'      }
  ]);

  RackPanel.superclass.constructor.call(this, {
    title: "Rack",
    listeners: {activate:function() { ChangeQuery(2);} },
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(RackPanel, Ext.grid.GridPanel);


HVCPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
   var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'a' }, { name: 'b' },{ name: 'c' }, { name: 'd' },
      { name: 'e' }, { name: 'f' },{ name: 'g' }, { name: 'h' }
    ],
    data:[
      [ 'H-1001', 'run', 'Core2Duo 2.4GHz', 3000 , '192.168.10.10', 'x86_64', '2F-22-001-00' , 'for test'],
      [ 'H-1002', 'stoped', 'Celeron 2GHz',    3000 , '192.168.11.10', 'i386'  , '1F-02-001-00' , 'Destroy'],
      [ 'H-2001', 'stoped', 'Core2Duo 1.6GHz', 3000 , '192.168.12.10', 'x86_64', '2F-22-002-00' , 'for test'],
      [ 'H-2003', 'run', 'Celeron 1GHz' ,   2000 , '192.168.13.10', 'i386'  , '2F-10-004-00' , 'for test'],
      [ 'H-3001', 'stoped', 'Celeron 1GHz',    2000 , '192.168.14.10', 'i386'  , '2F-10-005-00' , 'for test']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "HVC-ID", width: 100, dataIndex: 'a' },
    { header: "State", width: 60, dataIndex: 'b' },
    { header: "Manifest", width: 150, dataIndex: 'c' },
    { header: "Memory", width: 70, dataIndex: 'd' },
    { header: "Private IP", width: 80, dataIndex: 'e' },
    { header: "Architecture", width: 100, dataIndex: 'f' },
    { header: "Location", width: 120, dataIndex: 'g' },
    { header: "Memo", width: 120, dataIndex: 'h' }
  ]);

  var addWin = null;

  // private member
  function getSelectedHVCID()
  {
    var temp = sm.getCount();
    if(temp == 0){
      return null;
    }
    else{
      return sm.getSelected().get('a');
    }
  }

  HVCPanel.superclass.constructor.call(this, {
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "HVC",
    width: 320,
    autoHeight: false,
    stripeRows: true,
    listeners: {activate:function() { ChangeQuery(0);} },
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(HVCPanel, Ext.grid.GridPanel);

HVAPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'a' },{ name: 'b' },{ name: 'c' },{ name: 'd' },
      { name: 'e' },{ name: 'f' },{ name: 'g' },
      { name: 'h' }
    ],
    data:[ 
      [ 'HA-1001', 'run', 'Core2Duo 2.4GHz', 3000 , '192.168.10.10', 'x86_64', '2F-22-001-01' , 'for test'],
      [ 'HA-1002', 'stoped', 'Celeron 2GHz',    3000 , '192.168.11.10', 'i386'  , '2F-22-001-02' , 'Destroy'],
      [ 'HA-1003', 'stoped', 'Core2Duo 1.6GHz', 3000 , '192.168.12.10', 'x86_64', '2F-22-001-03' , 'for test'],
      [ 'HA-1004', 'run', 'Celeron 1GHz' ,   2000 , '192.168.13.10', 'i386'  , '2F-22-001-04' , 'for test'],
      [ 'HA-1005', 'stoped', 'Celeron 1GHz',    2000 , '192.168.14.10', 'i386'  , '2F-22-001-05' , 'for test']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "HVA-ID", width: 100, dataIndex: 'a' },
    { header: "State", width: 60, dataIndex: 'b' },
    { header: "Manifest", width: 150, dataIndex: 'c' },
    { header: "Memory", width: 70, dataIndex: 'd' },
    { header: "Private IP", width: 80, dataIndex: 'e' },
    { header: "Architecture", width: 100, dataIndex: 'f' },
    { header: "Location", width: 120, dataIndex: 'g' },
    { header: "Memo", width: 120, dataIndex: 'h' }
  ]);

  function getSelectedHVAID()
  {
    var temp = sm.getCount();
    if(temp == 0){
      return null;
    }
    else{
      return sm.getSelected().get('a');
    }
  }

  HVAPanel.superclass.constructor.call(this, {
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "HVA",
    width: 320,
    autoHeight: false,
    stripeRows: true,
    listeners: {activate:function() { ChangeQuery(1);} },
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(HVAPanel, Ext.grid.GridPanel);

VMPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:false});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'instance-id' },
      { name: 'server-id' },
      { name: 'account-id' },
      { name: 'user-id' },
      { name: 'wmi-id' },
      { name: 'state' },
      { name: 'public-dns' },
      { name: 'private-dns' },
      { name: 'private-ip' },
      { name: 'type' },
      { name: 'service' }
    ],
    data:[ 
//      [ '88939299', 'S1001', 39e9de9edd , '39de9d9','ssxxx','run', 'http://ssss/ssss','192.168.10.10', 'x86_64', '2F-22-001-01' , 'for test'],
    ]
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Instance-ID", width: 100, dataIndex: 'instance-id' },
    { header: "Server-ID", width: 120, dataIndex: 'server-id' },
    { header: "Account-ID", width: 120, dataIndex: 'account-id' },
    { header: "User-ID", width: 120, dataIndex: 'user-id' },
    { header: "WMI-ID", width: 120, dataIndex: 'wmi-id' },
    { header: "State", width: 120, dataIndex: 'state' },
    { header: "Public-DNS", width: 120, dataIndex: 'public-dns' },
    { header: "Public-IP", width: 120, dataIndex: 'public-ip' },
    { header: "Type", width: 120, dataIndex: 'type' },
    { header: "Service", width: 120, dataIndex: 'service' }
  ]);

  VMPanel.superclass.constructor.call(this, {
    title: "Instance",
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    listeners: {activate:function() { ChangeQuery(4);} },
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(VMPanel, Ext.grid.GridPanel);

ServerQueryPanel = function(){
  ServerQueryPanel.superclass.constructor.call(this, {
    height:70,
    region: 'north',
    frame : true,
    bodyStyle:'padding:5px',
    items: [{
      layout:'column',
      items:[{
        columnWidth:.8,
        layout: 'form',
        items: [{
            fieldLabel: 'Keyword',
            xtype: 'textfield',
            name: 'account-id',
            anchor: '100%'
        }]
      },{
        labelWidth: 5, 
        columnWidth:.2,
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
            data: [[1,'include'],[2, 'exact']]
          }),
          triggerAction: 'all',
		  value:'1',
          valueField: 'myId',
          displayField: 'displayText'
        }]
      }]
    }],
	buttons: [{
	  text:'Search',
	  handler: function(){
        alert('Search');
	  },
	  scope:this
	}]
  });
}
Ext.extend(ServerQueryPanel, Ext.form.FormPanel);

AddMapWindow = function(){
    var form = new Ext.form.FormPanel({
      width: 400,
      frame:true,
      bodyStyle:'padding:5px 5px 0',
      fileUpload: true,
      items: [{
        fieldLabel: 'Map-Name',
        xtype: 'textfield',
        name: 'account-id',
        anchor: '100%'
      }, {
        fieldLabel: 'Map-File',
        xtype: 'textfield',
        inputType: 'file',
        width: 200,
        name: 'map-file',
        anchor: '100%'
/*     }, {
        xtype: 'fileuploadfield',
        id: 'map-file',
        emptyText: 'Select an file',
        fieldLabel: 'Map-File',
        name: 'map-file',
        buttonText: 'file'
*/
      }, {
        fieldLabel: 'Memo',
        xtype: 'textarea',
        name: 'form_textfield',
        anchor: '100%'
      }]
    });

    AddMapWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      height: 220,
      width: 400,
	  layout:'fit',
      title: 'Add Map',
	  items: [form],
	  buttons: [{
		text:'OK',
	  },{
		text: 'Close',
		handler: function(){
			this.close();
		},
		scope:this
	  }]
    });
}
Ext.extend(AddMapWindow, Ext.Window);

ResourceEditorPanel = function(){
  var mtabPanel  = new MAPTabPanel('center',600);
  mtabPanel.add(new MAPViewPanel('1F-100'));
  mtabPanel.add(new MAPViewPanel('1F-101'));
  mtabPanel.add(new MAPViewPanel('2F-101'));
  mtabPanel.add(new MAPViewPanel('2F-200'));
  mtabPanel.add(new MAPViewPanel('3F-105'));
  mtabPanel.add(new MAPViewPanel('3F-200'));

  var palletPanel = new PalletPanel();
  var resourceTreePanel = new ResourceTreePanel();
  var resourcePropertyPanel = new ResourcePropertyPanel();
  var editPanel = new Ext.Panel({
    region: 'east',
    width: 150,
    defaults     : { flex : 1 }, //auto stretch
    layoutConfig : { align : 'stretch' },
    split: true,
	layout: 'vbox',
    items : [palletPanel,resourceTreePanel,resourcePropertyPanel]
  });

  ResourceEditorPanel.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
    items: [mtabPanel,editPanel]
  });
}
Ext.extend(ResourceEditorPanel, Ext.Panel);

CenterLogPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'action' },
      { name: 'date-time' },
      { name: 'target' },
      { name: 'account-name' },
      { name: 'user-name' },
      { name: 'message' }
    ],
    data:[
      [ 'lauch', '2009/12/1 11:10:10' , 'instance',  'axsh_soumu', 'ito', 'xxxxx'],
      [ 'save',  '2009/12/2 15:00:20' ,  'wmi',      'axsh_eigyo', 'muto', 'xxxxx'],
      [ 'stop' , '2009/12/3 19:00:05' , 'instance',  'axsh_soumu', 'kato', 'xxxxx']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "DateTime",    width: 150, dataIndex: 'date-time' },
    { header: "Action",      width: 100, dataIndex: 'action'   },
    { header: "Target",      width: 100, dataIndex: 'target'    },
    { header: "Account-Name",width: 100, dataIndex: 'account-name'  },
    { header: "User-Name"   ,width: 100, dataIndex: 'user-name'  },
    { header: "Message",     width: 350, dataIndex: 'message' }
  ]);

  CenterLogPanel.superclass.constructor.call(this, {
    region: "south",
    title: 'Center Log',
    cm:clmnModel,
    sm:sm,
    split: true,
    height: 200,
    store: store,
    stripeRows: true,
    tbar : [
      { text : 'Search',
        handler:function(){
          var win = new SearchLogWindow();
          win.show();
        }
      }
    ],
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
   });
}
Ext.extend(CenterLogPanel, Ext.grid.GridPanel);

PalletPanel = function(){
  PalletPanel.superclass.constructor.call(this, {
    split: true,
    width: 150,
    layout: {
      type:'vbox',
      padding:'5',
      align:'stretch'
    },
    defaults:{margins:'0 0 5 0'},
    items:[{
      xtype:'button',
      text: 'Add Rack'
    },{
      xtype:'button',
      text: 'Remove Rack'
    },{
      xtype:'button',
      text: 'Edit Rack'
    },{
      xtype:'button',
      text: 'Select Range'
    },{
      xtype:'button',
      text: 'Lock'
    },{
      xtype:'button',
      text: 'UnLock'
    }]
  });
}
Ext.extend(PalletPanel, Ext.Panel);

ResourceTreePanel = function(){
  ResourceTreePanel.superclass.constructor.call(this,{
    split: true,
    title: 'Server',
    border: false,
    useArrows:true,
    width: 160,
    rootVisible: false,
    tbar : [
      { 
        iconCls: 'icon-add',
        handler:function(){
          alert('Add');
        }
      },
      { iconCls: 'icon-delete',
        handler:function(){
          alert('Remove');
         }
      },
      { iconCls: 'icon-edit',
        handler:function(){
          alert('Edit');
        }
      }
    ],
    root:{
      text:      '',
      draggable: false,
      id:        'root',
      expanded:  true,
      children:  [
        {
          id:       'child1',
          text:     'RACK-AAAA',
          expanded:  true,
          children:  [
            {
              id:       'menu01',
              text:     'Server0001',
              leaf:     true
            },
            {
              id:       'menu02',
              text:     'Server0002',
              leaf:     true
            }
          ]
        },
        {
          id:       'child2',
          text:     'RACK-BBBB',
          expanded:  true,
          children:  [
            {
              id:       'menu03',
              text:     'ServerAAAAA',
              leaf:     true
            }
          ]
        }
      ]
    }
  });
}
Ext.extend(ResourceTreePanel, Ext.tree.TreePanel);

ResourcePropertyPanel = function(){
  ResourcePropertyPanel.superclass.constructor.call(this, {
    title: "Property",
    autoScroll: true,
    split: true,
    width: 150,
    bodyStyle:'padding:15px',
    html: 'XXXXXXXX'
  });
}
Ext.extend(ResourcePropertyPanel, Ext.Panel);

SearchLogWindow = function(){
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
            fieldLabel: 'Action',
            xtype: 'textfield',
            name: 'actoin',
            anchor: '100%'
          }, {
            fieldLabel: 'Target',
            xtype: 'textfield',
            name: 'target',
            anchor: '100%'
          }, {
            fieldLabel: 'Account-Nmae',
            xtype: 'textfield',
            name: 'account-name',
            anchor: '100%'
          }, {
            fieldLabel: 'User-Name',
            xtype: 'textfield',
            name: 'user-name',
            anchor: '100%',
          }, {
            fieldLabel: 'Message',
            xtype: 'textfield',
            name: 'message',
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
          }]
        }]
      }]
    });
    SearchLogWindow.superclass.constructor.call(this, {
        iconCls: 'icon-panel',
        height: 220,
        width: 500,
		layout:'fit',
        title: 'Search Log',
		items: [form],
		buttons: [{
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
Ext.extend(SearchLogWindow, Ext.Window);
