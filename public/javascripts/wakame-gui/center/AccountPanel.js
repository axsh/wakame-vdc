
AccountPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/account-list',
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

  this.refresh = function(){
      store.reload();
  }

  AccountPanel.superclass.constructor.call(this, {
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "Account Management",
    width: 320,
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
          var addWin = new AddAccountWindow(this);
		  addWin.show();
        }
      },'-',
      { iconCls: 'removeUser',
        text : 'Remove', handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/account-remove',
	        method: "POST", 
            params : 'id=' + sm.getSelected().id,
            success: function(form, action) {
              store.reload();
            }
	      });
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
Ext.extend(AccountPanel, Ext.grid.GridPanel);

AddAccountWindow = function(accountPanel){
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
      xtype: 'checkboxgroup',
      items: [
        {boxLabel: 'Enable', name: 'en' }
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
          handler: function(){
            form.getForm().submit({
              url: '/account-create',
              waitMsg: 'Adding...',
              method: 'POST',
              scope: this,
              success: function(form, action) {
                accountPanel.refresh();
	            this.close();
              },
              failure: function(form, action) {
                alert('Add account failure.');
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
        id: 'id',
        value: accountData.get('id'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Account-Name',
        xtype: 'textfield',
        name: 'nm',
        value: accountData.get('nm'),
        anchor: '100%'
        }
        ,{
        fieldLabel: '',
        xtype: 'checkboxgroup',
        items: [
          { boxLabel: 'Enable',
            name: 'enable',
            checked: accountData.get('en')
          }
        ]
        }
        ,{
        fieldLabel: 'Contract-Date',
        xtype: 'textfield',
        name: 'contract-date',
        value: accountData.get('cn'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Memo',
        xtype: 'textarea',
        name: 'form_textarea',
        value: accountData.get('mm'),
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
            id: 'id',
            anchor: '100%'
          }, {
            fieldLabel: 'Account-Name',
            xtype: 'textfield',
            id: 'nm',
            anchor: '100%'
          }, {
            fieldLabel: 'Enable',
            xtype: 'checkbox',
            anchor: '100%',
            items: [{
	          name: "enable",
              boxLabel: 'Enable',
              id: 'en',
              checked : true
	        }]
          }, {
            fieldLabel: 'Contract-Date',
            xtype: 'datefield',
            id: 'cn',
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

