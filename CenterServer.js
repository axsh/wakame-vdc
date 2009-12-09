var westPanel = null;
var hvcPanel = null;
var hvaPanel = null;
var mapPanel = null;
var mapgPanel = null;
var centerPanel = null;
var panelMode = 0;

Ext.onReady(function(){

  Ext.BLANK_IMAGE_URL='./js/resources/images/default/s.gif';

  centerPanel = new CradPanel();
  westPanel   = new WestPanel();
  viewport    = new Ext.Viewport({
    layout: 'border',
    items:[ centerPanel, westPanel]
  });
});

function ChangePanel(md)
{
  if(panelMode != md){
    panelMode = md;
    if(panelMode == 1){
       var id = hvcPanel.getSelectedHVCID();
       if(id != null){
         hvaPanel.setTitle('HVA List : '+ id);
       }
       else{
//         以下では、選択できなかった
//var sm  = westPanel.getSelectionModel();
//var sel = sm.getSelectedNode();
//sm.select(sel);
//sm.unselect(sel);
//sel = westPanel.getNodeById('menu01');
//sel.select();

         return;
       }
    }
    centerPanel.layout.setActiveItem(panelMode);
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
    animate: true,
    width: 150,
    listeners: {
      'click': function(node){
          if(node.id == 'menu01'){
            ChangePanel(0);
          }
          if(node.id == 'menu02'){
            ChangePanel(1);
          }
          if(node.id == 'menu03'){
            ChangePanel(2);
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
          text:     'Server',
          expanded:  true,
          children:  [
            {
              id:       'menu01',
              text:     'HVC List',
              leaf:     true
            },
            {
              id:       'menu02',
              text:     'HVA List',
              leaf:     true
            },
            {
              id:       'menu03',
              text:     'MAP',
              leaf:     true
            }
          ]
        }
      ]
    }
  });
}
Ext.extend(WestPanel, Ext.tree.TreePanel);

CradPanel = function(){

  hvcPanel = new HVCPanel();
  hvaPanel = new HVAPanel();
  mapPanel = new MAPPanel();
  mapgPanel= new MAPGPanel();


  CradPanel.superclass.constructor.call(this, {
    id: 'mycard',
    region: 'center',
    layout:'card',
	activeItem: 0, 
	defaults: {
		border:false
	},
	items: [hvcPanel,hvaPanel,mapPanel,mapgPanel]
  });
}
Ext.extend(CradPanel, Ext.Panel);

HVCPanel = function(){

  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});

   var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'a' },
      { name: 'b' },
      { name: 'c' },
      { name: 'd' },
      { name: 'e' },
      { name: 'f' },
      { name: 'g' },
      { name: 'h' }
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
  // public member
  this.getSelectedHVCID = function()
  {
    return getSelectedHVCID();	// call private member
  }

  function changeURL()
  {
    // 使えない。
    // javascript:window.navigate("http://www.google.co.jp/");
    // こちらはOK
	javascript:window.location.href = "http://www.google.co.jp/";
  }

  HVCPanel.superclass.constructor.call(this, {
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "HVC List",
    width: 320,
    autoHeight: true,
    stripeRows: true,
    tbar : [
      { text : 'Lauch',
        handler:function(){
          var dt = getSelectedHVCID();
          if(dt == null){ return; }
          alert('Lauch : '+ dt);
        }
      },
      { text : 'Add',handler:function(){
          if(addWin == null){
            addWin = new AddHVCWindow();
          }
          addWin.setTitle('Add HVC');
		  addWin.show();
        }
      },
      { text : 'Remove',handler:function(){
          var dt = getSelectedHVCID();
          if(dt == null){ return; }
          Ext.Msg.confirm("Remove:"+dt,"Are you share?", function(btn){
            if(btn == 'yes'){
              var rec = sm.getSelected();
              store.remove(rec);
            }
          });
         }
       },
      { text : 'Edit',handler:function(){
          alert('Edit');
// modify test
//          var rec = sm.getSelected();
//          rec.set('d',200);
//          store.reload();
changeURL();

        }
      },'->',
      { text : 'Logout',handler:function(){ alert('Logout'); } }
    ]
  });
}
Ext.extend(HVCPanel, Ext.grid.GridPanel);

HVAPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
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
    title: "HVA List",
    width: 320,
    autoHeight: true,
    stripeRows: true,
    tbar : [
      { text : 'Lauch',
        handler:function(){
          alert('Lauch');
        }
      },
      { text : 'Add',handler:function(){
          alert('ADD');
        }
      },
      { text : 'Remove',handler:function(){
          alert('Remove');
         }
       },
      { text : 'Edit',handler:function(){
          alert('Edit');
        }
      },'->',
      { text : 'Logout',handler:function(){ alert('Logout'); } }
    ]
  });
}
Ext.extend(HVAPanel, Ext.grid.GridPanel);

AddHVCWindow = function(){

    var form = new Ext.form.FormPanel({
      labelAlign: 'top',
      baseCls: 'x-plain',
      items: [
        {
        fieldLabel: 'HVC-ID',
        xtype: 'textfield',
        name: 'form_textfield',
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Manifest',
        xtype: 'textfield',
        name: 'form_textfield',
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Memory',
        xtype: 'textfield',
        name: 'form_textfield',
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Private IP',
        xtype: 'textfield',
        name: 'form_textfield',
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Architecture',
        xtype: 'combo',
        editable: false,
        typeAhead: true,
        triggerAction: 'all',
        forceSelection:true,
        width:135,
        mode: 'local',
        store: new Ext.data.ArrayStore({
          id: 1,
          fields: [
            'myId',
            'displayText'
          ],
          data: [[1, 'x86_64'], [2, 'i386']]
        }),
        valueField: 'myId',
        displayField: 'displayText'
        }
        ,{
        fieldLabel: 'Location',
        xtype: 'textfield',
        name: 'form_textfield',
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Memo',
        xtype: 'textfield',
        name: 'form_textfield',
        anchor: '100%'
        }
      ]
    });

    AddHVCWindow.superclass.constructor.call(this, {
        iconCls: 'icon-panel',

        collapsible:true,
        titleCollapse:true,
        width: 500,
        height: 450,

		layout:'fit',
		closeAction:'hide',
		modal: true,
		plain: true,
        defaults:{bodyStyle:'padding:15px'},

		items: [form],
		buttons: [{
			text:'Submit',
		},{
			text: 'Close',
			handler: function(){
				this.hide();
			},
			scope:this
		}]

    });
}
Ext.extend(AddHVCWindow, Ext.Window);

MAPPanel = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'a' },{ name: 'b' },{ name: 'c' },{ name: 'd' }
    ],
    data:[ 
      [ '1001', '1F', '10','....'],
      [ '1002', '1F', '11','memo'],
      [ '1003', '2F', '10','small'],
      [ '1004', '2F', '14','xxxx'],
      [ '1005', '3F', '10','xxxx']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    { header: "ID", width: 100, dataIndex: 'a' },
    { header: "Floor", width: 60, dataIndex: 'b' },
    { header: "Room Number", width: 150, dataIndex: 'c' },
    { header: "Memo", width: 120, dataIndex: 'd' }
  ]);

  MAPPanel.superclass.constructor.call(this, {
    store: store,
    cm:clmnModel,
    sm:sm,
    title: "Location Map List",
    width: 320,
    autoHeight: true,
    stripeRows: true,
    tbar : [
      { text : 'Add Map',
        handler:function(){
          alert('Add Map Window');
        }
      },
      { text : 'Remove',handler:function(){
          alert('Remove');
         }
       },
      { text : 'View',
        handler:function(){
          ChangePanel(3);;
        }
      },
      { text : 'Edit',handler:function(){
          alert('Edit');
        }
      },'->',
      { text : 'Logout',handler:function(){ alert('Logout'); } }
    ]
  });
}
Ext.extend(MAPPanel, Ext.grid.GridPanel);

MAPGPanel = function(){

  var addWin=null;

/*
  // htmlから重複しないdivエレメントを作る
  var makeDiv = (function () {
	    var div_no = 0;
	    // div_pageXの作成
	    return function(html) {
	        return = Ext.DomHelper.append(
	            'map_div',
	            {
	                id:'div_page'+(div_no++),
	                tag:  'div',
	                html: html
	            },
	            true // returnElement
	        );
	    }
  })();
*/

  MAPGPanel.superclass.constructor.call(this, {
    title: "Location Map",
    layout: 'fit',
    id: 'map_div',
    bodyStyle: "background-image:url(1F-10.jpeg); background-repeat: no-repeat; background-attachment: fixed;",
    listeners: {
      click: function(){
        alert("XXXXXXXXXXXX");
      }
    },
    tbar : [
      { text : 'Add Rack',
        handler:function(){

// makeDiv('AAAAA');
//var e = Ext.DomHelper.append('map_div','<div id="AAA">test</div>');
//alert(e.id);
// debugger; // for firebugs

          if(addWin == null){
            addWin = new AddRackWindow();
          }
		  addWin.show();
        }
      },
      { text : 'Edit Rack',handler:function(){
          alert('Edit Rack');
         }
       },
      { text : 'Back to List',
        handler:function(){
          ChangePanel(2);
        }
      },'->',
      { text : 'Logout',handler:function(){ alert('Logout'); } }
    ]
  });
}
Ext.extend(MAPGPanel, Ext.Panel);

AddRackWindow = function(){

  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'a' },{ name: 'b' },{ name: 'c' }
    ],
    data:[ 
      [ 'HVC', '----',          'Core2 Duo2.8GHz 4GB'],
      [ 'HVA', '192.168.10.10', 'Core2 Duo2.1GHz 2GB'],
      [ 'HVA', '192.168.10.10', 'Core2 Duo2.1GHz 2GB']
    ]
  });

  var listview = new Ext.ListView({
    store: store,
    singleSelect: true,
    multiSelect: false,
    columns: [
      { header: 'Kind', width: .2,  dataIndex: 'a' },
      { header: 'HVC IP', width: .2,  dataIndex: 'b' },
      { header: 'Spec',   dataIndex: 'c' }
    ]
  });

  AddRackWindow.superclass.constructor.call(this, {
        iconCls: 'icon-panel',

        collapsible:true,
        titleCollapse:true,
        width: 500,
        height: 450,

		layout:'fit',
		closeAction:'hide',
		modal: true,
		plain: true,
        defaults:{bodyStyle:'padding:15px'},
		items: listview,

        tbar : [
          { text : 'ADD HVC',
            handler:function(){
              alert('Add HVC'+listview.getSelectedIndexes());
            }
          },
          { text : 'ADD HVA',handler:function(){
              store.add(new store.reader.recordType({ a:'HVA', b:'192.168.10.10', c:'Core2 Duo1.6GHz 2GB' }))
            }
          }
        ],
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
Ext.extend(AddRackWindow, Ext.Window);
