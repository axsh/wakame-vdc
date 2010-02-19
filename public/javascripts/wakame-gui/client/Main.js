// Global Resources
Ext.apply(WakameGUI, {
  activePanel : 0,
  SystemAdminMain:null,
  SystemAdminSelector:null,
  SystemAdminUpPanel:null,
  SystemAdminDownPanel:null,
  SystemAdminQuery:null,
  SystemAdminCard:null
});

WakameGUI.SystemAdminSelector = function(mainPanel){
  var upPanel   = new WakameGUI.SystemAdminUpPanel();
  var downPanel = new WakameGUI.SystemAdminDownPanel(mainPanel.getCardPanel());
  this.getUpPanel = function(){
    return upPanel;
  }
  WakameGUI.SystemAdminSelector.superclass.constructor.call(this,{
    region: "west", 
    split: true,
    header: false,
    border: false,
    width: 150,
    layout: 'border',
	items: [upPanel,downPanel]
  });
}
Ext.extend(WakameGUI.SystemAdminSelector, Ext.Panel);

WakameGUI.SystemAdminUpPanel = function(){
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

  WakameGUI.SystemAdminUpPanel.superclass.constructor.call(this,{
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
Ext.extend(WakameGUI.SystemAdminUpPanel, Ext.Panel);

WakameGUI.SystemAdminDownPanel = function(cardPanel){
  function ChangePanel(no)
  {
    if(WakameGUI.activePanel != no){
      WakameGUI.activePanel = no;
      cardPanel.layout.setActiveItem(WakameGUI.activePanel);
      switch(no) {
          case 0:
            cardPanel.refreshPanel('instancePanel');
          break;
                    
          case 1:
            cardPanel.refreshPanel('imagePanel');
          break;
          
          case 2:
            //cardPanel.refreshPanel('clusterPanel');
          break;
          
          case 3:
            //cardPanel.refreshPanel('servicePanel');            
          break;
      }
    }
  }

  WakameGUI.SystemAdminDownPanel.superclass.constructor.call(this,{
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
Ext.extend(WakameGUI.SystemAdminDownPanel, Ext.tree.TreePanel);

WakameGUI.SystemAdminMain = function(){
  var adminQuery = new WakameGUI.SystemAdminQuery();
  var cardPanel  = new WakameGUI.SystemAdminCard();

  this.getCardPanel = function(){
    return cardPanel;
  }

  this.setUpPanel = function(obj){
    cardPanel.setUpPanel(obj)
  }

  WakameGUI.SystemAdminMain.superclass.constructor.call(this, {
    region: 'center',
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [adminQuery,cardPanel]
  });
}
Ext.extend(WakameGUI.SystemAdminMain, Ext.Panel);

WakameGUI.SystemAdminQuery = function(){
  WakameGUI.SystemAdminQuery.superclass.constructor.call(this, {
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
Ext.extend(WakameGUI.SystemAdminQuery, Ext.form.FormPanel);

WakameGUI.SystemAdminCard = function(){
  var instancePanel = new WakameGUI.Instance();
  var imagePanel    = new WakameGUI.Image();
  var clusterPanel  = new WakameGUI.Cluster();
  var servicePanel  = new WakameGUI.Service();

  imagePanel.setInstancePanel(instancePanel);

  this.setUpPanel = function(obj){
    imagePanel.setUpPanel(obj)
  }

  this.refreshPanel = function(panel){
      eval(panel).refresh();
  }

  WakameGUI.SystemAdminCard.superclass.constructor.call(this, {
    region: 'center',
    layout:'card',
	activeItem: 0, 
	defaults: {
		border:false
	},
	items: [instancePanel,imagePanel,clusterPanel,servicePanel]
  });
}
Ext.extend(WakameGUI.SystemAdminCard, Ext.Panel);

Ext.onReady(function(){
  Ext.BLANK_IMAGE_URL='/javascripts/ext-js/resources/images/default/s.gif';
  Ext.QuickTips.init();
  var mainPanel     = new WakameGUI.SystemAdminMain();
  var selectorPanel = new WakameGUI.SystemAdminSelector(mainPanel);
  mainPanel.setUpPanel(selectorPanel.getUpPanel());

  var headerPanel   = new WakameGUI.Header('System Administrator Tool');
  var footerPanel   = new WakameGUI.Footer();
  viewport = new Ext.Viewport({
    layout: 'border',
    items:[ headerPanel, mainPanel, selectorPanel, footerPanel]
  });
});
