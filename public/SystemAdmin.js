var cardPanel = null;
var panelMode = 0;
var upPanel = null;
var instancePanel = null;
var imagePanel = null;

Ext.onReady(function(){
  Ext.BLANK_IMAGE_URL='./javascripts/ext-js/resources/images/default/s.gif';
  Ext.QuickTips.init();
  var centerPanel = new CenterPanel();
  var westPanel   = new WestPanel();
  var northPanel  = new NorthPanel('System Administrator Tool');
  var southPanel  = new SouthPanel();
  viewport    = new Ext.Viewport({
    layout: 'border',
    items:[ northPanel, centerPanel, westPanel, southPanel]
  });
});

function ChangePanel(md)
{
  if(panelMode != md){
    panelMode = md;
    cardPanel.layout.setActiveItem(panelMode);
  }
}

WestPanel = function(){
  upPanel = new UpPanel();
  var downPanel = new DownPanel();

  WestPanel.superclass.constructor.call(this,{
    region: "west", 
    split: true,
    header: false,
    border: false,
    width: 150,
    layout: 'border',
	items: [upPanel,downPanel]
  });
}
Ext.extend(WestPanel, Ext.Panel);

UpPanel = function(){

  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/account-list',
      method:'GET'
    }),
    listeners: {
      'load': function( temp , records, ope ){
        if(records.length > 0){
          combo.setValue(records[0].id);
        }
      }
    },
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id'    ,type:'string'},
        { name:'nm'    ,type:'string'}
      ]
    })
  });
  store.load();

  var combo = new Ext.form.ComboBox({
    typeAhead: true,
    lazyRender:true,
    editable: false,
    width: 120, 
    triggerAction: 'all',
    forceSelection:true,
    mode: 'local',
    store: store,
    valueField: 'id',
    displayField: 'nm'
  });

  var form = new Ext.form.FormPanel({
      labelWidth: 5, 
      width: 100,
      baseCls: 'x-plain',
      items: [ combo ]
  });

  this.getSelectedAccount = function(){
    return combo.value;
  }

  UpPanel.superclass.constructor.call(this,{
    region: "north", 
    split: true,
    height: 60,
    border: false,
    title: 'Account',
    defaults:{bodyStyle:'padding:5px'},
    layout: 'fit',
    items: [form]
  });
}
Ext.extend(UpPanel, Ext.Panel);

DownPanel = function(){
  DownPanel.superclass.constructor.call(this,{
    region: "center", 
    split: true,
    header: false,
    border: false,
    useArrows:true,
    enableDD:false,
    width: 150,
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
          text:     'Infrastructure',
          expanded:  true,
          children:  [
            {
              id:       'menu01',
              text:     'Instance',
              leaf:     true
            },
            {
              id:       'menu02',
              text:     'Image',
              leaf:     true
            }
          ]
        },
        {
          id:       'child2',
          text:     'PlatHome',
          expanded:  true,
          children:  [
            {
              id:       'menu03',
              text:     'Cluster',
              leaf:     true
            },
            {
              id:       'menu04',
              text:     'Service',
              leaf:     true
            }
          ]
        }
      ]
    }
  });
}
Ext.extend(DownPanel, Ext.tree.TreePanel);

CenterPanel = function(){
  var adminQuery = new AdminQueryPanel();
  cardPanel    = new CardPanel();

  CenterPanel.superclass.constructor.call(this, {
    region: 'center',
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [adminQuery,cardPanel]
  });
}
Ext.extend(CenterPanel, Ext.Panel);

AdminQueryPanel = function(){
  AdminQueryPanel.superclass.constructor.call(this, {
    height:80,
    region: 'north',
    frame : true,
    bodyStyle:'padding:0px 0px 0',
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
Ext.extend(AdminQueryPanel, Ext.form.FormPanel);

CardPanel = function(){
  instancePanel = new InstancePanel();
  imagePanel = new ImagePanel();
  var clusterPanel = new ClusterPanel();
  var servicePanel = new ServicePanel();

  CardPanel.superclass.constructor.call(this, {
    region: 'center',
    layout:'card',
	activeItem: 0, 
	defaults: {
		border:false
	},
	items: [instancePanel,imagePanel,clusterPanel,servicePanel]
  });
}
Ext.extend(CardPanel, Ext.Panel);

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
        { name:'ac' ,type:'string'},
        { name:'is' ,type:'string'},
        { name:'dc' ,type:'string'}
      ]
    })
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "WMI-ID",       width: 100, dataIndex: 'id' },
    { header: "Name",         width: 100, dataIndex: 'nm' },
    { header: "Owner",        width: 100, dataIndex: 'od' },
    { header: "Visibility",   width: 100, dataIndex: 'vy' },
    { header: "Architecture", width: 100, dataIndex: 'ac'  },
    { header: "Image-size",   width: 100, dataIndex: 'is'  },
    { header: "Description",  width: 100, dataIndex: 'dc'  }
  ]);

  toolbar = new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
  });

  this.refresh = function(){
    toolbar.refresh() 
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
}
Ext.extend(ImagePanel, Ext.grid.GridPanel);

InstancePanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/instance-list',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id' ,type:'string'},
        { name:'od' ,type:'string'},
        { name:'wd' ,type:'string'},
        { name:'st' ,type:'string'},
        { name:'pub-dns' ,type:'string'},
        { name:'pri-dns' ,type:'string'},
        { name:'ip' ,type:'string'},
        { name:'tp' ,type:'string'},
        { name:'sv' ,type:'string'}
      ]
    })
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Instance ID" ,width: 100, dataIndex: 'id'},
    { header: "Owner"       ,width: 100, dataIndex: 'od'},
    { header: "WMI ID"      ,width: 100, dataIndex: 'wd'},
    { header: "State"       ,width: 80,  dataIndex: 'st'},
    { header: "Public DNS"  ,width: 100, dataIndex: 'pub-dns'},
    { header: "Private DNS" ,width: 100, dataIndex: 'pri-dns'},
    { header: "Private IP"  ,width: 100, dataIndex: 'ip'},
    { header: "type"        ,width: 50,  dataIndex: 'tp'},
    { header: "Service"     ,width: 100, dataIndex: 'sv'}
  ]);

  InstancePanel.superclass.constructor.call(this, {
    title: 'Instance',
    store: store,
    cm:clmnModel,
    sm:sm,
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
      { text : 'Reboot',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/instance-reboot',
	        method: "POST", 
            params : 'id=' + sm.getSelected().id
	      }); 
        }
      },
      { text : 'Terminate',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/instance-terminate',
	        method: "POST", 
            params : 'id=' + sm.getSelected().id
	      }); 
        }
      },
      { text : 'Save',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/instance-save',
	        method: "POST", 
            params : 'id=' + sm.getSelected().id
	      }); 
        }
      }
    ]
  });
  store.load({params: {start: 0, limit: 50}});		// limit = page size
}
Ext.extend(InstancePanel, Ext.grid.GridPanel);

ClusterPanel = function(){
  var clistPanel = new ClusterListPanel();
  var cctrlPanel = new ClusterCtrlPanel();
  ClusterPanel.superclass.constructor.call(this, {
    title: 'Cluster',
    width: 320,
    header: false,
    border: false,
    layout: 'border',
	items: [clistPanel,cctrlPanel]
  });
}
Ext.extend(ClusterPanel, Ext.Panel);

ClusterListPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'cluster-id' },
      { name: 'name' },
      { name: 'state' },
      { name: 'public-dns' }
    ],
    data:[
      [ 'AA9999995', 'Blog', 'running',  'axsh1.com/sssss/']
    ]
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Cluster ID", width: 100, dataIndex: 'cluster-id' },
    { header: "Name", width: 100, dataIndex: 'name' },
    { header: "State", width: 50, dataIndex: 'state' },
    { header: "Public DNS", width: 100, dataIndex: 'public-dns' }
  ]);

  ClusterListPanel.superclass.constructor.call(this, {
    region: 'center',
    store: store,
    cm:clmnModel,
    sm:sm,
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
    })
  });
}
Ext.extend(ClusterListPanel, Ext.grid.GridPanel);

ClusterCtrlPanel = function(){

  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'app-name' },
      { name: 'state' },
      { name: 'now' },
      { name: 'future' },
      { name: 'setting' }
    ],
    data:[
      [ 'Apache', 'running', '2',  '2', ''],
      [ 'LB',     'running', '1',  '1', ''],
      [ 'MySQL',  'running', '1',  '1', '']
    ]
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Application", width: 100, dataIndex: 'app-name' },
    { header: "state", width: 100, dataIndex: 'state' },
    { header: "Now", width: 50, dataIndex: 'now' },
    { header: "Future", width: 50, dataIndex: 'future' },
    { header: "Setting", width: 50, dataIndex: 'setting' }
  ]);

  ClusterCtrlPanel.superclass.constructor.call(this, {
    region: 'east',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 380,
    split: true,
    autoHeight: true,
    stripeRows: true,
    tbar : [
      { text : 'Reboot',handler:function(){}
      },
      { text : 'Terminate',handler:function(){}
      },
      { text : 'Backup',handler:function(){}
      },
      { text : 'Restore',handler:function(){}
      }
    ]
  });
}
Ext.extend(ClusterCtrlPanel, Ext.grid.GridPanel);

ServicePanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({

    fields: [
      { name: 'wmi-id' },
      { name: 'name' },
      { name: 'owner-id' },
      { name: 'visibility' },
      { name: 'architecture' }
    ],
    data:[
      [ 'WK-2009', 'Blog', 'O10001', 'public', 'i386'],
      [ 'WK-2011', 'SNS', 'O10001', 'public', 'i386']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "WMI-ID", width: 100, dataIndex: 'wmi-id' },
    { header: "Name", width: 100, dataIndex: 'name' },
    { header: "Owner", width: 100, dataIndex: 'owner-id' },
    { header: "Visibility", width: 100, dataIndex: 'visibility' },
    { header: "Architecture", width: 100, dataIndex: 'architecture'  }
  ]);

  ServicePanel.superclass.constructor.call(this, {
    title: 'Service',
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
    }),
    tbar : [
      { text : 'Launch',handler:function(){}
      },
      { text : 'Delete',handler:function(){}
      }
    ]
  });
}
Ext.extend(ServicePanel, Ext.grid.GridPanel);

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
	  },
	  scope:this
	},{
	  text: 'Close',
	  handler: function(){
	  this.hide();
	  },
	  scope:this
	}]
  });
}
Ext.extend(LaunchWindow, Ext.Window);
