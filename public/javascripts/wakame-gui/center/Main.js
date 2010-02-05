/*
	Wakame GUI Main (Center)  -*- coding: utf-8 -*-
*/
Ext.onReady(function(){
  Ext.BLANK_IMAGE_URL='./javascripts/ext-js/resources/images/default/s.gif';
  Ext.QuickTips.init();

  var mainPanel     = new MainPanel();
  var selectorPanel = new SelectorPanel(mainPanel);
  var headerPanel   = new HeaderPanel('DataCenter Manager');
  var footerPanel   = new FooterPanel();
  viewport = new Ext.Viewport({
    layout: 'border',
    items:[ headerPanel, mainPanel, selectorPanel, footerPanel]
  });
});

SelectorPanel = function(centerPanel){
  var panelMode = 0;
  function ChangePanel(md)
  {
    if(panelMode != md){
      panelMode = md;
      centerPanel.layout.setActiveItem(panelMode);
    } 
  }

  SelectorPanel.superclass.constructor.call(this,{
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
      children:[
        {
          id:       'child1',
          text:     'Manage',
          expanded:  true,
          children:[
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
          children:[
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
          children:[
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
Ext.extend(SelectorPanel, Ext.tree.TreePanel);

MainPanel = function(){
  var accountPanel  = new AccountPanel();
  var userPanel = new UserPanel();
  var resourceViewerPanel = new ResourceViewerPanel();
  var resourceEditorPanel = new ResourceEditorPanel();
  var locationMapPanel = new LocationMapPanel();
  var logViewerPanel = new LogViewerPanel();
  MainPanel.superclass.constructor.call(this, {
	region:'center',
	layout:'card',
	activeItem: 0,
	defaults: {border:false},
	items: [accountPanel,userPanel,resourceViewerPanel,resourceEditorPanel,locationMapPanel,logViewerPanel]
  });
}
Ext.extend(MainPanel, Ext.Panel);
