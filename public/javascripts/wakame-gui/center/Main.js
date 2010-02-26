/*-
 * Copyright (c) 2010 axsh co., LTD.
 * All rights reserved.
 *
 * Author: Takahisa Kamiya
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

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
  Ext.BLANK_IMAGE_URL='/javascripts/ext-js/resources/images/default/s.gif';
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
          if(node.id == 'menu01'){
            WakameGUI.changePanel(centerPanel,'accountPanel',0);
          }
          else if(node.id == 'menu02'){
            WakameGUI.changePanel(centerPanel,'userPanel',1);
          }
          else if(node.id == 'menu03'){
            // WakameGUI.changePanel(centerPanel,'resourceViewerPanel',2);
          }
          else if(node.id == 'menu04'){
            // WakameGUI.changePanel(centerPanel,'resourceEditorPanel',3);
          }
          else if(node.id == 'menu05'){
            // WakameGUI.changePanel(centerPanel,'locationMapPanel',4);
          }
          else if(node.id == 'menu06'){
            // WakameGUI.changePanel(centerPanel,'logViewerPanel',5);
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
  
  this.refreshPanel = function(panel){
      eval(panel).refresh();
  }

  WakameGUI.Main.superclass.constructor.call(this, {
	region:'center',
	layout:'card',
	activeItem: 0,
	defaults: {border:false},
	items: [accountPanel,userPanel,resourceViewerPanel,resourceEditorPanel,locationMapPanel,logViewerPanel]
  });
}
Ext.extend(WakameGUI.Main, Ext.Panel);
