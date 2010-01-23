/*
	Wakame GUI Main (Center)  -*- coding: utf-8 -*-
*/
// Global Resources
Ext.apply(WakameGUI, {
  activePanel : 0,
  Main:null,
  Selector:null
});

Ext.onReady(function(){
  Ext.BLANK_IMAGE_URL='./javascripts/ext-js/resources/images/default/s.gif';
  Ext.QuickTips.init();
  var mainPanel     = new WakameGUI.Main();
  var selectorPanel = new WakameGUI.Selector(mainPanel);
  var headerPanel   = new WakameGUI.Header('DataCenter Manager');
  var footerPanel   = new WakameGUI.Footer();
  viewport = new Ext.Viewport({
    layout: 'border',
    items:[ headerPanel, mainPanel, selectorPanel, footerPanel]
  });
});

WakameGUI.Selector = function(centerPanel){
  var panelMode = 0;
  function ChangePanel(no)
  {
      console.debug(no);
    
      if(WakameGUI.activePanel != no){
        WakameGUI.activePanel = no;
        centerPanel.layout.setActiveItem(WakameGUI.activePanel);
        if(WakameGUI.activePanel == 0){
          // centerPanel.refreshInstance();
        }
        else if(WakameGUI.activePanel == 1){
          // centerPanel.refreshImage();
        }else if(WakameGUI.activePanel == 2){
            
        }
      }
      
    // if(panelMode != md){
    //   panelMode = md;
    //   centerPanel.layout.setActiveItem(panelMode);
    // } 
  }

  WakameGUI.Selector.superclass.constructor.call(this,{
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
          //console.debug(node.id);
          
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
Ext.extend(WakameGUI.Selector, Ext.tree.TreePanel);

WakameGUI.Main = function(){
  var accountPanel        = new WakameGUI.Account();
  var userPanel           = new WakameGUI.User();
  var resourceViewerPanel = new WakameGUI.ResourceViewer();
  var resourceEditorPanel = new WakameGUI.ResourceEditor();
  var locationMapPanel    = new WakameGUI.LocationMap();
  var logViewerPanel      = new WakameGUI.LogViewer();
  
  var centerPanel  = new WakameGUI.Selector();

  this.getCardPanel = function(){
    return cardPanel;
  }

  this.setUpPanel = function(obj){
    cardPanel.setUpPanel(obj)
  }
  
  this.refreshInstance = function(){
    centerPanel.refresh();
  }

  // this.refreshImage = function(){
  //   centerPanel.refresh();
  // }
  WakameGUI.Main.superclass.constructor.call(this, {
	region:'center',
	layout:'card',
	activeItem: 0,
	defaults: {border:false},
	items: [accountPanel,userPanel,resourceViewerPanel,resourceEditorPanel,locationMapPanel,logViewerPanel]
  });
}
Ext.extend(WakameGUI.Main, Ext.Panel);
