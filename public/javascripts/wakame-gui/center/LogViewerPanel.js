// Global Resources
Ext.apply(WakameGUI, {
  LogViewer:null
});

WakameGUI.LogViewer = function(){
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
  WakameGUI.LogViewer.superclass.constructor.call(this, {
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
    loadMask: {msg: 'Loading...'},
    bbar: new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
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
}
Ext.extend(WakameGUI.LogViewer, Ext.grid.GridPanel);
