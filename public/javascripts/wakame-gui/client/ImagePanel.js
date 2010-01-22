
var instancePanel = null;

ImagePanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true}); 
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/image-list',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id' ,type:'string'},
        { name:'nm' ,type:'string'},
        { name:'od' ,type:'string'},
        { name:'vy' ,type:'string'},
        { name:'ac' ,type:'string'}
      ]
    })
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "WMI-ID",       width: 100, dataIndex: 'id' },
    { header: "Manifest",     width: 200, dataIndex: 'nm' },
    { header: "Owner",        width: 100, dataIndex: 'od' },
    { header: "Visibility",   width: 100, dataIndex: 'vy' },
    { header: "Architecture", width: 100, dataIndex: 'ac' }
  ]);

  toolbar = new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
  });

  var upPanel = null;

  this.refresh = function(){
    store.reload();
  }

  this.setUpPanel = function(obj){
    upPanel = obj;
  }

  this.setInstancePanel = function(obj){
    instancePanel = obj;
  }

  ImagePanel.superclass.constructor.call(this, {
    title: 'Image',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    bbar: toolbar,
    tbar : [
      { text : 'Launch',handler:function(){
		  var temp = sm.getCount();
		  if(temp > 0){
            var aid  =  upPanel.getSelectedAccount();
            var data = sm.getSelected();
			var launchWin = new LaunchWindow(data,aid);
			launchWin.show();
          }
        }
      },
      { text : 'Delete',handler:function(){}
      }
    ]
  });
  store.load({params: {start: 0, limit: 50}});		// limit = page size
  Ext.TaskMgr.start({
    run: function(){
      store.reload();
    },
    interval: 60000
  });
}
Ext.extend(ImagePanel, Ext.grid.GridPanel);

LaunchWindow = function(launchData,account_id){
  var form = new Ext.form.FormPanel({
    labelWidth: 70, 
    width: 150,
    baseCls: 'x-plain',
    items: [
    {
      fieldLabel: 'WMI-ID',
      xtype: 'displayfield',
      value: launchData.get('id'),
      anchor: '100%'
    }
    ,{
      fieldLabel: 'Name',
      xtype: 'displayfield',
      value: launchData.get('nm'),
      anchor: '100%'
    },
    {
      xtype: 'hidden',
      id: 'wd',
      value: launchData.get('id'),
    }
    ,{
      xtype: 'hidden',
      id: 'id',
      value: account_id,
    }
    ,{
      fieldLabel: 'TYPE',
      xtype: 'textfield',
      id: 'tp',
      width: 80
    }]
  });

  LaunchWindow.superclass.constructor.call(this, {
    iconCls: 'icon-panel',
    collapsible:true,
    titleCollapse:true,
    width: 250,
    height: 200,
	layout:'fit',
	closeAction:'hide',
    title: 'Launch',
	modal: true,
	plain: true,
    defaults:{bodyStyle:'padding:15px'},
	items: [form],
	buttons: [{
	  text:'Launch',
      handler: function(){
        form.getForm().submit({
          url: '/instance-create',
          waitMsg: 'creating...',
          method: 'POST',
          scope: this,
          success: this.submitSuccess,
          failure: this.submitFailure
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
Ext.extend(LaunchWindow, Ext.Window , {
  submitSuccess: function(form, action){
    this.close();
    instancePanel.refresh();
  },
  submitFailure: function(form, action){
    alert('Create failure.');
    this.close();
  }
});
